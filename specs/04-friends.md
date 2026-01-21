# Spécification Système d'Amis

## États d'amitié

- `pending` - Demande envoyée, en attente
- `accepted` - Amis mutuels
- `blocked` - Utilisateur bloqué

## Fonctionnalités

### Envoyer une demande
1. Rechercher un utilisateur
2. Cliquer "Ajouter"
3. Création friendship avec status=pending

### Recevoir une demande
1. Notification (badge sur l'icône amis)
2. Liste des demandes en attente
3. Accepter → status=accepted
4. Refuser → suppression de la row

### Liste d'amis
- Affichage des amis acceptés
- Statut en ligne/hors ligne
- Actions: Message, Supprimer

### Bloquer
- Empêche l'envoi de messages
- Masque de la recherche
