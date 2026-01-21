# Spécification Fonctionnalités Chat

## Messages

### Envoi
- Input texte avec bouton envoyer
- Raccourci Enter pour envoyer
- Shift+Enter pour nouvelle ligne
- Validation: message non vide, max 2000 caractères

### Affichage
- Messages groupés par date
- Avatar + username de l'expéditeur
- Horodatage (relatif: "il y a 5 min", absolu si > 24h)
- Scroll automatique vers le bas pour nouveaux messages

### Temps réel
- Supabase Realtime pour nouveaux messages
- Indicateur de typing (optionnel)

## Conversations

### Privées
- Entre 2 utilisateurs
- Création via profil ami ou recherche

### Groupes
- Nom et avatar personnalisables
- Rôles: admin (créateur) et membres
- Admin peut ajouter/retirer des membres

## Recherche

### Messages
- Recherche full-text dans les messages
- Filtrage par conversation
- Pagination des résultats

### Utilisateurs
- Recherche par username
- Pour ajouter des amis ou créer des conversations

## Pagination

- Infinite scroll pour les messages (charger 50 par batch)
- Charger les anciens messages en scrollant vers le haut
