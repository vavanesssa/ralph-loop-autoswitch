# Amis - Spécifications

## Vue d'ensemble
Système de réseau d'amis avec recherche, demandes et liste.

## Domaines

### 1. User Search
- Input de recherche par username/email
- Liste de résultats
- Pagination (25 résultats par page)
- Désactiver self dans résultats

### 2. Friendship Flow
- Bouton "Ajouter ami" sur résultats recherche
- Création demande avec statut "pending"
- Notification quand reçu

### 3. Friend List
- Liste des amis acceptés
- Status online/offline/away
- Avatar + username
- Actions rapides (conversation, supprimer)

### 4. Friend Requests
- Liste des demandes en attente (entrantes)
- Boutons: Accepter, Refuser
- Badge compteur
- Notification badge (optionnel)

## URLs
- `/friends` - Page amis (à implémenter)
- `/friends/requests` - Page demandes entrantes
