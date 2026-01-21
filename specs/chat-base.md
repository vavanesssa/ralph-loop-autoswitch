# Chat Base - Spécifications

## Vue d'ensemble
Interface de chat principal avec conversation list, affichage messages, envoi messages en temps réel.

## Domaines

### 1. Data Structure
- Conversation: id, name, type (private/group), created_at, updated_at
- Message: id, conversation_id, user_id, content, created_at
- Participant: conversation_id, user_id, role

### 2. Conversation List
- Liste des conversations dans sidebar
- Dernier message preview
- Timestamp du dernier message
- Badge "non-lu" (optionnel)
- Online status indicator
- Avatar de groupe pour conversations privées

### 3. Message Display
- Groupement par date (messages du même jour)
- Avatar du sender
- Username du sender
- Timestamp relatif (à l'instant, il y a X minutes)
- Formatage simple (sauts de ligne, balises HTML limitées)

### 4. Message Input
- Input texte avec prévisualisation
- Button d'envoi (ou Enter pour envoyer)
- Validation: ne pas envoyer message vide
- Auto-scroll vers bas quand message envoyé

### 5. Realtime Updates
- Supabase Realtime subscription
- Nouveaux messages en temps réel
- Typing indicators (optionnel)
- Status de connection realtime

## URLs
- `/chat/[conversationId]` - Page conversation
- `/chat` - Page conversations list (si unique)
