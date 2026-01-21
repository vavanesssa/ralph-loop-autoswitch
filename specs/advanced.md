# Fonctionnalités Avancées - Spécifications

## Vue d'ensemble
Fonctionnalités supplémentaires pour enrichir l'expérience chat.

## Domaines

### 1. Message Search
- Barre de recherche globale dans header
- Filtrage par keyword dans contenu message
- Filtrage par conversation (dropdown)
- Highlight des résultats trouvés
- Résultats limités à 50 (pas d'infinite scroll ici)

### 2. Message Pagination
- Infinite scroll vers le haut (charger plus anciens messages)
- Détection de fin de conversation
- Loading skeleton pendant fetch
- Optimistic updates (ne pas avoir à attendre)

### 3. User Presence
- Status: online, offline, away
- Visibilité en temps réel avec Supabase
- Gestion manuelle par l'utilisateur (setting)
- Indicateurs visuels dans conversations et liste amis

## URLs
- `/search` - Recherche globale (à implémenter)
- `/settings` - Préférences (à implémenter)
