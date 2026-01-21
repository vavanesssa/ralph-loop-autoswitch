# Ralph Loop Multi-IA

> Un seul fichier. Une commande. L'IA fait le reste.

## TL;DR

```bash
# 1. Décris ton projet
echo "Je veux une API REST pour gérer des todos avec auth JWT" > PROJECT.md

# 2. Lance
./ralph-loop.sh

# 3. Valide le plan quand demandé
# 4. Reviens quand c'est fini
```

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   PROJECT.md                                                    │
│   "Je veux une app de..."                                       │
│         │                                                       │
│         ▼                                                       │
│   ┌─────────────┐                                               │
│   │   IA #1     │  Génère specs + plan                         │
│   │  (Claude)   │─────────────────────┐                        │
│   └─────────────┘                     │                        │
│         │ rate limit                  ▼                        │
│         ▼                     ┌──────────────┐                 │
│   ┌─────────────┐             │  "Ce plan    │                 │
│   │   IA #2     │             │  te convient?"│                 │
│   │  (Gemini)   │             └──────────────┘                 │
│   └─────────────┘                     │                        │
│         │                             │ oui                    │
│         ▼                             ▼                        │
│   ┌─────────────┐             ┌──────────────┐                 │
│   │   IA #3     │◄────────────│   BUILD      │                 │
│   │  (Codex)    │             │   AUTO       │                 │
│   └─────────────┘             └──────────────┘                 │
│         │                             │                        │
│         └─────────────────────────────┘                        │
│                       │                                         │
│                       ▼                                         │
│              <promise>COMPLETE</promise>                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Installation

```bash
# Prérequis
brew install jq  # ou apt install jq

# Setup
chmod +x ralph-loop.sh
./ralph-loop.sh health
```

## Fichiers

```
ralph-multiloop/
├── ralph-loop.sh       # LE script
├── ralph-config.json   # Config (auto-généré)
├── PROMPT.md           # Instructions pour l'IA
└── PROJECT.md          # TON projet (à créer)
```

## PROJECT.md - Ton seul input

```markdown
# Mon Projet

Je veux une application web pour gérer mes recettes de cuisine.

## Fonctionnalités
- Ajouter/modifier/supprimer des recettes
- Recherche par ingrédient
- Catégories (entrée, plat, dessert)
- Export PDF

## Stack souhaitée
- Next.js
- PostgreSQL
- Tailwind CSS

## Contraintes
- Doit tourner en local
- Pas de dépendance cloud
```

L'IA s'occupe de :
- Créer les specs détaillées
- Découper en tâches atomiques
- Te présenter le plan
- Tout implémenter après validation

## Commandes

```bash
./ralph-loop.sh          # Démarre
./ralph-loop.sh health   # Status des CLI
./ralph-loop.sh reset    # Repart de zéro
```

## Le flux

1. **Tu écris** PROJECT.md (ce que tu veux)
2. **Tu lances** `./ralph-loop.sh`
3. **L'IA analyse** et crée un plan
4. **Tu valides** (oui/non/éditer)
5. **L'IA build** tout seul avec failover automatique
6. **Tu reviens** quand c'est fini

## Failover automatique

- Claude épuisé → Gemini
- Gemini épuisé → Codex
- Codex épuisé → Copilot
- Tous épuisés → Attend et reprend

**Aucune intervention manuelle.**

## Configuration

`ralph-config.json` (auto-généré) :

```json
{
  "cli_priority": ["claude", "gemini", "codex"],
  "timeout_seconds": 300,
  "cooldown_seconds": 300
}
```

## FAQ

**Q: Et si je veux modifier le plan ?**
R: Quand le script demande "Ce plan te convient ?", tape `e` pour éditer.

**Q: Comment arrêter ?**
R: `Ctrl+C`

**Q: Comment recommencer ?**
R: `./ralph-loop.sh reset` puis modifie PROJECT.md

**Q: Ça marche avec quels CLI ?**
R: Claude Code, Gemini CLI, OpenAI Codex, GitHub Copilot, OpenCode

## C'est tout

```bash
./ralph-loop.sh
```
