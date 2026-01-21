#!/usr/bin/env bash
set -euo pipefail

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
}

create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
{
  "cli_priority": ["claude", "gemini", "codex", "copilot", "opencode"],
  "timeout_seconds": 300,
  "max_retries_per_cli": 3,
  "cooldown_seconds": 300,
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

    [[ $now -lt $cooldown ]] && return 1
    command -v "$cmd" &>/dev/null || return 1
    timeout 5s "$cmd" --version &>/dev/null 2>&1 || timeout 5s "$cmd" --help &>/dev/null 2>&1 || return 1
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
execute_with_cli() {
    local cli="$1" prompt="$2"
    local full_cmd="${CLI_COMMANDS[$cli]}"

    [[ "$cli" != "$LAST_CLI" ]] && [[ -n "$LAST_CLI" ]] && log "SWITCH" "━━━ $LAST_CLI → $cli ━━━"
    CURRENT_CLI="$cli"

    local tmp=$(mktemp)
    local exit_code=0

    timeout "${TIMEOUT_SEC}s" bash -c "echo \"\$1\" | $full_cmd" -- "$prompt" > "$tmp" 2>&1 || exit_code=$?

    local output=$(cat "$tmp")
    rm -f "$tmp"

    [[ $exit_code -eq 124 ]] && { log "WARN" "$cli timeout"; return 2; }

    if detect_rate_limit "$cli" "$output"; then
        log "WARN" "⚠️  $cli RATE LIMIT"
        CLI_COOLDOWN_UNTIL[$cli]=$(($(date +%s) + COOLDOWN_SEC))
        return 3
    fi

    if [[ $exit_code -eq 0 ]]; then
        LAST_CLI="$cli"
        echo "$output"
        return 0
    fi

    return 1
}

execute_with_failover() {
    local prompt="$1"

    for cli in "${CLI_ORDER[@]}"; do
        check_cli_health "$cli" || continue

        local attempt=0
        while [[ $attempt -lt $MAX_RETRIES ]]; do
            ((attempt++))
            local output exit_code=0
            output=$(execute_with_cli "$cli" "$prompt") || exit_code=$?

            case $exit_code in
                0) echo "$output"; return 0 ;;
                3) break ;;  # rate limit, next CLI
                *) sleep $((2 ** (attempt - 1))) ;;
            esac
        done
    done

    # Tous épuisés - attendre
    local now=$(date +%s) min_wait=999999
    for cli in "${CLI_ORDER[@]}"; do
        local cd="${CLI_COOLDOWN_UNTIL[$cli]:-0}"
        [[ $cd -gt $now ]] && [[ $((cd - now)) -lt $min_wait ]] && min_wait=$((cd - now))
    done

    if [[ $min_wait -lt 999999 ]]; then
        log "INFO" "Attente ${min_wait}s..."
        sleep "$min_wait"
        execute_with_failover "$prompt"
        return $?
    fi

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
        ((iteration++))

        local phase="BUILD"
        check_plan_approved || phase="PLAN"

        log "INFO" "━━━ Itération $iteration [$phase] [$CURRENT_CLI] ━━━"

        local prompt=$(cat "$PROMPT_FILE")
        local output

        if output=$(execute_with_failover "$prompt"); then
            echo "$output" > "last_output.log"

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

        sleep 2
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
