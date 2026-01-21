#!/usr/bin/env bash
set -euo pipefail

# Require bash 4+ for associative arrays
if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo "Error: This script requires bash 4+. You have bash ${BASH_VERSION}"
    echo "On macOS: brew install bash && add /opt/homebrew/bin/bash to /etc/shells"
    echo "Then: chsh -s /opt/homebrew/bin/bash"
    exit 1
fi

# Ensure Homebrew and common paths are available
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

#=============================================================================
# RALPH LOOP MULTI-IA - Version Simplifiée
#=============================================================================
#
# Usage: ./ralph-loop.sh
#
# 1. Écris ce que tu veux dans PROJECT.md
# 2. Lance le script
# 3. L'IA crée le plan et te demande validation
# 4. Tu valides → ça build tout seul
#
#=============================================================================

CONFIG_FILE="${CONFIG_FILE:-ralph-config.json}"
LOG_FILE="${LOG_FILE:-ralph-loop.log}"
MAX_ITERATIONS="${MAX_ITERATIONS:-100}"
PROMPT_FILE="${PROMPT_FILE:-PROMPT.md}"
PLAN_FILE="IMPLEMENTATION_PLAN.md"

CURRENT_CLI=""
LAST_CLI=""

declare -a CLI_ORDER=()
declare -A CLI_COMMANDS=()
declare -A CLI_COOLDOWN_UNTIL=()

TIMEOUT_SEC=300
MAX_RETRIES=3
COOLDOWN_SEC=300
INACTIVITY_SEC=30
LAST_OUTPUT_SIZE=0
LAST_ACTIVITY_TIME=0

#-----------------------------------------------------------------------------
# Couleurs
#-----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    local level="$1"; shift
    local color=""
    case "$level" in
        "INFO")   color="$GREEN" ;;
        "WARN")   color="$YELLOW" ;;
        "ERROR")  color="$RED" ;;
        "DEBUG")  color="$CYAN" ;;
        "SWITCH") color="$BLUE" ;;
        "ASK")    color="$PURPLE" ;;
        *)        color="$NC" ;;
    esac
    local ts=$(date '+%H:%M:%S')
    echo -e "${color}[$ts]${NC} $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# Affiche un countdown avec message personnalisé
countdown() {
    local seconds="$1"
    local message="${2:-Attente}"
    local color="${3:-$YELLOW}"
    
    for ((i=seconds; i>0; i--)); do
        printf "\r${color}${BOLD}⏳ ${message}: %3ds${NC}   " "$i"
        sleep 1
    done
    printf "\r${GREEN}✅ ${message}: terminé!${NC}       \n"
}

#-----------------------------------------------------------------------------
# Config
#-----------------------------------------------------------------------------
load_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    [[ ! -f "$CONFIG_FILE" ]] && [[ -f "$script_dir/$CONFIG_FILE" ]] && CONFIG_FILE="$script_dir/$CONFIG_FILE"
    [[ ! -f "$PROMPT_FILE" ]] && [[ -f "$script_dir/$PROMPT_FILE" ]] && PROMPT_FILE="$script_dir/$PROMPT_FILE"

    [[ ! -f "$CONFIG_FILE" ]] && create_default_config

    command -v jq &>/dev/null || { log "ERROR" "jq requis: brew install jq"; exit 1; }

    mapfile -t CLI_ORDER < <(jq -r '.cli_priority[]' "$CONFIG_FILE")

    for cli in "${CLI_ORDER[@]}"; do
        local cmd=$(jq -r ".cli_configs.$cli.command" "$CONFIG_FILE")
        local flags=$(jq -r ".cli_configs.$cli.flags" "$CONFIG_FILE")
        CLI_COMMANDS[$cli]="$cmd $flags"
        CLI_COOLDOWN_UNTIL[$cli]=0
    done

    TIMEOUT_SEC=$(jq -r '.timeout_seconds // 300' "$CONFIG_FILE")
    MAX_RETRIES=$(jq -r '.max_retries_per_cli // 3' "$CONFIG_FILE")
    COOLDOWN_SEC=$(jq -r '.cooldown_seconds // 300' "$CONFIG_FILE")
    INACTIVITY_SEC=$(jq -r '.inactivity_seconds // 60' "$CONFIG_FILE")
}

create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "cli_priority": ["opencode", "claude", "codex", "gemini", "copilot"],
  "timeout_seconds": 300,
  "max_retries_per_cli": 3,
  "cooldown_seconds": 300,
  "inactivity_seconds": 30,
  "completion_markers": ["<promise>COMPLETE</promise>", "<promise>DONE</promise>"],
  "approval_patterns": ["plan te convient", "this plan ok", "approve this plan", "valider ce plan"],
  "cli_configs": {
    "claude": {
      "command": "claude",
      "flags": "--dangerously-skip-permissions -p --output-format json",
      "rate_limit_patterns": ["rate limit", "rate_limited", "429", "exhausted"],
      "refusal_patterns": ["Usage Policy", "refusal"]
    },
    "gemini": {
      "command": "gemini",
      "flags": "--yolo -p --output-format json",
      "rate_limit_patterns": ["RESOURCE_EXHAUSTED", "rateLimitExceeded", "429"],
      "refusal_patterns": ["BLOCKED", "SAFETY"]
    },
    "codex": {
      "command": "codex",
      "flags": "--yolo exec",
      "rate_limit_patterns": ["rate_limit_exceeded", "insufficient_quota", "429"],
      "refusal_patterns": ["content_policy_violation"]
    },
    "copilot": {
      "command": "copilot",
      "flags": "--allow-all-tools -p",
      "rate_limit_patterns": ["rate limit", "token usage exceeded"],
      "refusal_patterns": []
    },
    "opencode": {
      "command": "opencode",
      "flags": "-p -f json -q",
      "rate_limit_patterns": ["429", "Rate limit exceeded"],
      "refusal_patterns": []
    }
  }
}
EOF
}

#-----------------------------------------------------------------------------
# CLI Health & Detection
#-----------------------------------------------------------------------------
check_cli_health() {
    local cli="$1"
    local cmd="${CLI_COMMANDS[$cli]%% *}"
    local now=$(date +%s)
    local cooldown="${CLI_COOLDOWN_UNTIL[$cli]:-0}"

    # En cooldown ?
    if [[ $now -lt $cooldown ]]; then
        local remaining=$((cooldown - now))
        log "DEBUG" "⏸️  $cli en cooldown (${remaining}s restantes)"
        return 1
    fi

    # Commande existe ?
    if ! command -v "$cmd" &>/dev/null; then
        log "DEBUG" "❌ $cli non trouvé dans PATH"
        return 1
    fi

    log "DEBUG" "✓ $cli disponible"
    return 0
}

detect_rate_limit() {
    local cli="$1" output="$2"
    local patterns=$(jq -r ".cli_configs.$cli.rate_limit_patterns[]" "$CONFIG_FILE" 2>/dev/null)
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        echo "$output" | grep -qi "$p" && return 0
    done <<< "$patterns"
    return 1
}

detect_completion() {
    local output="$1"
    local markers=$(jq -r '.completion_markers[]' "$CONFIG_FILE" 2>/dev/null)
    while IFS= read -r m; do
        [[ -z "$m" ]] && continue
        echo "$output" | grep -qF "$m" && return 0
    done <<< "$markers"
    return 1
}

detect_approval_request() {
    local output="$1"
    local patterns=$(jq -r '.approval_patterns[]' "$CONFIG_FILE" 2>/dev/null)
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        echo "$output" | grep -qi "$p" && return 0
    done <<< "$patterns"
    return 1
}

#-----------------------------------------------------------------------------
# Execution
#-----------------------------------------------------------------------------

# Affiche GENERATING en rouge avec animation et temps écoulé/timeout
show_generating() {
    local pid="$1"
    local tmp_file="$2"
    local start_time=$(date +%s)
    local last_size=0
    local inactive_count=0
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    
    # Formatage du timeout
    local timeout_display
    if [[ $TIMEOUT_SEC -ge 60 ]]; then
        local mins=$((TIMEOUT_SEC / 60))
        local secs=$((TIMEOUT_SEC % 60))
        if [[ $secs -eq 0 ]]; then
            timeout_display="${mins}min"
        else
            timeout_display="${mins}m${secs}s"
        fi
    else
        timeout_display="${TIMEOUT_SEC}s"
    fi
    
    while kill -0 "$pid" 2>/dev/null; do
        local now=$(date +%s)
        local elapsed=$((now - start_time))
        local current_size=$(stat -f%z "$tmp_file" 2>/dev/null || echo "0")
        
        # Formatage temps écoulé
        local elapsed_display
        if [[ $elapsed -ge 60 ]]; then
            local e_mins=$((elapsed / 60))
            local e_secs=$((elapsed % 60))
            elapsed_display="${e_mins}m${e_secs}s"
        else
            elapsed_display="${elapsed}s"
        fi
        
        if [[ "$current_size" -gt "$last_size" ]]; then
            # Nouvelle sortie détectée
            last_size=$current_size
            inactive_count=0
            printf "\r${RED}${BOLD}🔴 GENERATING ${spinner[$i]}${NC} [${elapsed_display}/${timeout_display}]    "
        else
            ((inactive_count++)) || true
            local inactive_secs=$((inactive_count))
            
            if [[ $inactive_secs -ge $INACTIVITY_SEC ]]; then
                printf "\r${YELLOW}${BOLD}⚠️  INACTIF ${inactive_secs}s${NC} [${elapsed_display}/${timeout_display}]    "
            else
                printf "\r${RED}${BOLD}🔴 GENERATING ${spinner[$i]}${NC} [${elapsed_display}/${timeout_display}] (idle: ${inactive_secs}s/${INACTIVITY_SEC}s)    "
            fi
        fi
        
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 1
    done
    printf "\r                                                              \r"
}

# Détection d'inactivité - retourne 0 si inactif trop longtemps
check_inactivity() {
    local tmp_file="$1"
    local start_time="$2"
    local last_size="$3"
    
    local current_size=$(stat -f%z "$tmp_file" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local elapsed=$((now - start_time))
    
    if [[ "$current_size" -eq "$last_size" ]] && [[ $elapsed -ge $INACTIVITY_SEC ]]; then
        return 0  # Inactif
    fi
    return 1
}

execute_with_cli() {
    local cli="$1" prompt="$2"
    local full_cmd="${CLI_COMMANDS[$cli]}"

    if [[ "$cli" != "$LAST_CLI" ]] && [[ -n "$LAST_CLI" ]]; then
        echo ""
        log "SWITCH" "🔄 SWITCH: $LAST_CLI → $cli"
        echo ""
    fi
    CURRENT_CLI="$cli"

    log "INFO" "🚀 Exécution: $full_cmd"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ 🤖 $cli en cours...                                            ${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    local tmp=$(mktemp)
    local exit_code=0
    local start_time=$(date +%s)

    # Lance la commande en background
    timeout "${TIMEOUT_SEC}s" bash -c "echo \"\$1\" | $full_cmd" -- "$prompt" > "$tmp" 2>&1 &
    local cmd_pid=$!
    
    # Lance le monitoring en background
    show_generating "$cmd_pid" "$tmp" &
    local monitor_pid=$!
    
    # Boucle de surveillance d'inactivité
    local last_size=0
    local inactivity_start=$(date +%s)
    
    while kill -0 "$cmd_pid" 2>/dev/null; do
        local current_size=$(stat -f%z "$tmp" 2>/dev/null || echo "0")
        local now=$(date +%s)
        
        if [[ "$current_size" -gt "$last_size" ]]; then
            last_size=$current_size
            inactivity_start=$now
        else
            local inactive_duration=$((now - inactivity_start))
            if [[ $inactive_duration -ge $INACTIVITY_SEC ]]; then
                log "WARN" "⚠️  Inactivité détectée (${inactive_duration}s) - Relance..."
                kill "$cmd_pid" 2>/dev/null || true
                kill "$monitor_pid" 2>/dev/null || true
                wait "$cmd_pid" 2>/dev/null || true
                rm -f "$tmp"
                return 4  # Code spécial pour inactivité
            fi
        fi
        sleep 1
    done
    
    # Arrête le monitoring
    kill "$monitor_pid" 2>/dev/null || true
    wait "$cmd_pid" 2>/dev/null
    exit_code=$?
    
    # Affiche l'output capturé
    echo -e "${GREEN}${BOLD}✅ RÉPONSE REÇUE${NC}"
    echo ""
    cat "$tmp"
    
    local output=$(cat "$tmp")
    rm -f "$tmp"

    echo ""
    echo -e "${CYAN}└───────────────────── FIN $cli ─────────────────────┘${NC}"

    # Timeout ?
    if [[ $exit_code -eq 124 ]]; then
        log "WARN" "⏱️  $cli TIMEOUT après ${TIMEOUT_SEC}s"
        return 2
    fi

    # Rate limit ?
    if detect_rate_limit "$cli" "$output"; then
        echo ""
        log "WARN" "🚫 $cli RATE LIMIT DÉTECTÉ - Cooldown ${COOLDOWN_SEC}s"
        CLI_COOLDOWN_UNTIL[$cli]=$(($(date +%s) + COOLDOWN_SEC))
        return 3
    fi

    # Succès
    if [[ $exit_code -eq 0 ]]; then
        log "INFO" "✅ $cli terminé avec succès"
        LAST_CLI="$cli"
        # On sauvegarde l'output pour la détection de complétion
        echo "$output" > /tmp/ralph_last_output.txt
        return 0
    fi

    # Erreur
    log "WARN" "❌ $cli erreur (code: $exit_code)"
    return 1
}

execute_with_failover() {
    local prompt="$1"

    log "DEBUG" "🔍 Recherche d'un CLI disponible..."

    for cli in "${CLI_ORDER[@]}"; do
        if ! check_cli_health "$cli"; then
            continue
        fi

        local attempt=0
        while [[ $attempt -lt $MAX_RETRIES ]]; do
            ((attempt++)) || true
            log "INFO" "📡 Tentative $attempt/$MAX_RETRIES avec $cli"
            
            local exit_code=0
            execute_with_cli "$cli" "$prompt" || exit_code=$?

            case $exit_code in
                0) 
                    return 0 
                    ;;
                3) 
                    log "WARN" "⏭️  Rate limit sur $cli, passage au CLI suivant..."
                    break 
                    ;;  
                2)
                    log "WARN" "⏭️  Timeout sur $cli, passage au CLI suivant..."
                    break
                    ;;
                4)
                    log "WARN" "🔄 Inactivité détectée sur $cli, relance immédiate..."
                    # Ne pas incrémenter attempt, on relance directement
                    ((attempt--)) || true
                    countdown 2 "Relance"
                    ;;
                *) 
                    local wait_time=$((2 ** (attempt - 1)))
                    log "WARN" "🔄 Retry $attempt/$MAX_RETRIES pour $cli (erreur $exit_code)"
                    countdown "$wait_time" "Retry $cli"
                    ;;
            esac
        done
    done

    # Tous les CLI épuisés - calculer attente
    log "WARN" "😴 Tous les CLI épuisés ou en cooldown"
    
    local now=$(date +%s) min_wait=999999
    for cli in "${CLI_ORDER[@]}"; do
        local cd="${CLI_COOLDOWN_UNTIL[$cli]:-0}"
        if [[ $cd -gt $now ]] && [[ $((cd - now)) -lt $min_wait ]]; then
            min_wait=$((cd - now))
        fi
    done

    if [[ $min_wait -lt 999999 ]]; then
        log "INFO" "⏳ Attente de ${min_wait}s avant retry..."
        countdown "$min_wait" "Cooldown"
        execute_with_failover "$prompt"
        return $?
    fi

    log "ERROR" "💀 Aucun CLI disponible!"
    return 1
}

#-----------------------------------------------------------------------------
# Plan Approval
#-----------------------------------------------------------------------------
check_plan_approved() {
    [[ -f "$PLAN_FILE" ]] && grep -q "\[APPROVED\]" "$PLAN_FILE" && return 0
    return 1
}

mark_plan_approved() {
    if [[ -f "$PLAN_FILE" ]]; then
        if ! grep -q "\[APPROVED\]" "$PLAN_FILE"; then
            sed -i.bak '1a\
[APPROVED]
' "$PLAN_FILE"
            rm -f "${PLAN_FILE}.bak"
        fi
    fi
}

ask_user_approval() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                    📋 PLAN GÉNÉRÉ                            ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ -f "$PLAN_FILE" ]]; then
        cat "$PLAN_FILE"
    fi

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Ce plan te convient ?${NC}"
    echo ""
    echo "  [y/oui]  → Approuver et lancer le build"
    echo "  [n/non]  → Modifier PROJECT.md et relancer"
    echo "  [e/edit] → Éditer le plan manuellement"
    echo ""

    read -p "Choix: " choice

    case "${choice,,}" in
        y|yes|oui|o)
            mark_plan_approved
            log "INFO" "✅ Plan approuvé - Lancement du build..."
            return 0
            ;;
        e|edit)
            ${EDITOR:-nano} "$PLAN_FILE"
            mark_plan_approved
            log "INFO" "✅ Plan modifié et approuvé"
            return 0
            ;;
        *)
            log "INFO" "❌ Plan rejeté - Modifie PROJECT.md et relance"
            exit 0
            ;;
    esac
}

#-----------------------------------------------------------------------------
# Main Loop
#-----------------------------------------------------------------------------
ralph_loop() {
    local iteration=0

    # Vérifier PROJECT.md
    if [[ ! -f "PROJECT.md" ]]; then
        log "ERROR" "PROJECT.md introuvable!"
        echo ""
        echo "Crée un fichier PROJECT.md avec ce que tu veux construire."
        echo "Exemple:"
        echo ""
        echo "  # Mon Projet"
        echo "  Je veux une API REST pour gérer des todos avec auth JWT."
        echo ""
        exit 1
    fi

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          🔄 RALPH LOOP - MODE AUTONOME                       ║${NC}"
    echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║  CLI: ${CLI_ORDER[*]}${NC}"
    echo -e "${BOLD}║  Projet: PROJECT.md${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    while [[ $iteration -lt $MAX_ITERATIONS ]]; do
        ((iteration++)) || true

        local phase="BUILD"
        check_plan_approved || phase="PLAN"

        echo ""
        echo -e "${BOLD}╭───────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${BOLD}│  📍 ITÉRATION $iteration / $MAX_ITERATIONS                                          │${NC}"
        echo -e "${BOLD}│  📋 Phase: $phase                                                │${NC}"
        echo -e "${BOLD}│  🤖 CLI actuel: ${CURRENT_CLI:-aucun}                                        │${NC}"
        echo -e "${BOLD}╰───────────────────────────────────────────────────────────────╯${NC}"
        echo ""

        local prompt=$(cat "$PROMPT_FILE")

        if execute_with_failover "$prompt"; then
            # Lire l'output sauvegardé
            local output=""
            [[ -f /tmp/ralph_last_output.txt ]] && output=$(cat /tmp/ralph_last_output.txt)
            cp /tmp/ralph_last_output.txt last_output.log 2>/dev/null || true

            # Check completion
            if detect_completion "$output"; then
                echo ""
                echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║          ✅ PROJET TERMINÉ !                                 ║${NC}"
                echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
                echo -e "${GREEN}║  Itérations: $iteration${NC}"
                echo -e "${GREEN}║  Dernier CLI: $CURRENT_CLI${NC}"
                echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                return 0
            fi

            # Check approval request (only in PLAN phase)
            if [[ "$phase" == "PLAN" ]] && detect_approval_request "$output"; then
                ask_user_approval
            fi
        fi

        countdown 2 "Prochaine itération"
    done

    log "WARN" "Limite d'itérations atteinte"
    return 1
}

#-----------------------------------------------------------------------------
# Entry Point
#-----------------------------------------------------------------------------
show_help() {
    cat << 'EOF'

🔄 RALPH LOOP - Développement Autonome

USAGE:
    ./ralph-loop.sh              Démarre la boucle
    ./ralph-loop.sh health       Vérifie les CLI disponibles
    ./ralph-loop.sh reset        Repart de zéro (supprime le plan)

WORKFLOW:
    1. Écris ce que tu veux dans PROJECT.md
    2. Lance ./ralph-loop.sh
    3. L'IA crée un plan et te demande validation
    4. Tu approuves → ça construit tout seul

EOF
}

show_health() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║         Status des CLI                 ║"
    echo "╠════════════════════════════════════════╣"
    for cli in "${CLI_ORDER[@]}"; do
        local icon="❌" status="UNAVAILABLE"
        if check_cli_health "$cli" 2>/dev/null; then
            icon="✅"
            status="READY"
        fi
        printf "║  %s %-10s : %-12s       ║\n" "$icon" "$cli" "$status"
    done
    echo "╚════════════════════════════════════════╝"
    echo ""
}

reset_project() {
    rm -f "$PLAN_FILE" last_output.log ralph-loop.log
    rm -rf specs/
    mkdir -p specs
    log "INFO" "Projet réinitialisé. Modifie PROJECT.md et relance."
}

main() {
    load_config

    case "${1:-}" in
        health|status) show_health ;;
        reset|clean)   reset_project ;;
        help|--help|-h) show_help ;;
        *) ralph_loop ;;
    esac
}

main "$@"
