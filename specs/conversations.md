# Conversations - Spécifications

## Vue d'ensemble
Création et gestion des conversations privées et groupes.

## Domaines

### 1. Private Conversations
- Sélection d'un utilisateur pour créer conversation privée
- Unicité: pas de doublon conversation même utilisateurs
- Nommage automatique avec le nom des participants
- Avatar mix des avatars participants

### 2. Group Conversations
- Nom personnalisé pour le groupe
- Sélection multiple de participants
- Avatar générée automatiquement (premiers participants)
- Possibilité d'ajouter/supprimer membres
- Role: admin (créateur), member

### 3. Conversation UI
- Header avec nom/avatar
- Liste des membres (groupes uniquement)
- Options: quitter conversation (si membre), fermer dialog
- Badge admin pour créateur

## URLs
- `/chat` - Liste conversations
- `/chat/new?mode=private/group` - Dialog création
