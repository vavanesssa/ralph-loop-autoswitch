# Spécifications - Chat System

## Objectif
Système de messagerie en temps réel avec conversations privées et groupales, responsive et intuitif.

## Fonctionnalités Principales

### 1. Liste des Conversations
- Sidebar gauche avec liste des conversations
- Affichage avatar, nom, dernier message, timestamp
- Badge de notification (non-lu)
- Tri par date de dernière activité
- Menu contextuel (créer groupe, nouveau DM)

**UI Layout:**
```
┌─────────────────────┬─────────────────────────┐
│  [Étoile]           │   Zone Messages          │
│  Conversations      │   [Titre conversation]  │
│  ───────────────    │   ──────────────────    │
│  Avatar  User A     │   ──────────────────    │
│    msg preview      │   [Message]             │
│  Avatar  Group X    │   [Message]             │
│    last message     │   ──────────────────    │
│  Avatar  User B     │   [Message]             │
│    (online)         │                         │
└─────────────────────┴─────────────────────────┘
```

**Données:**
```typescript
interface Conversation {
  id: string;
  type: 'direct' | 'group';
  name?: string;
  last_message?: string;
  last_message_at?: string;
  unread_count?: number;
  created_at: string;
  participants: Participant[];
}

interface Participant {
  user_id: string;
  username: string;
  avatar_url?: string;
  is_online?: boolean;
}
```

### 2. Zone de Messages
- Liste des messages chronologique
- Groupement par date (Today, Yesterday, etc.)
- Avatar + username + timestamp
- Scroll auto vers dernier message
- Compteur de messages non-lus

**Messages:**
```typescript
interface Message {
  id: string;
  conversation_id: string;
  user_id: string;
  username: string;
  avatar_url?: string;
  content: string;
  created_at: string;
  reactions?: Reaction[];
}

interface Reaction {
  id: string;
  user_id: string;
  user_name: string;
  emoji: string;
  created_at: string;
}
```

### 3. Input Message
- Champ texte multi-ligne
- Bouton envoi (ou Enter)
- Ajout de emojis
- Caractères restants

**UI:**
```
┌─────────────────────────────────────────────┐
│ [Avatar + User]                     [X:12]  │
│                                             │
│ Hey! Comment ça va?  [👍]                    │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│ Je vais bien, et toi?      [Envoyer]       │
└─────────────────────────────────────────────┘
```

### 4. Création Conversation
- Nouveau DM: Sélection d'un utilisateur
- Nouveau groupe: Nom + Sélection multiple
- Validation des membres (max 50 pour groupes)
- Feedback utilisateur

### 5. Realtime Updates
- Nouveau message en temps réel
- Status des participants (online/offline)
- Dernier message mis à jour dans sidebar
- Animations smooth

**Supabase Realtime:**
```typescript
// Subscription sur messages
const channel = supabase
  .channel('messages-channel')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'messages' }, (payload) => {
    handleNewMessage(payload.new as Message);
  })
  .subscribe();
```

### 6. Pagination Messages
- Lazy loading: Charger X messages au défilement
- Infinite scroll vers le haut
- Pagination API côté serveur

**Query Pagination:**
```typescript
const { data, error } = await supabase
  .from('messages')
  .select('*')
  .order('created_at', { ascending: true })
  .lt('created_at', last_message.created_at)
  .limit(20);
```

### 7. Recherche Messages
- Input recherche globale
- Filtrage par conversation
- Highlight des résultats
- Résultats limités aux 10 derniers jours

**Query:**
```typescript
const { data, error } = await supabase
  .from('messages')
  .select(`
    *,
    profiles:user_id(username, avatar_url),
    reactions(*)
  `)
  .ilike('content', `%${searchQuery}%`)
  .order('created_at', { ascending: false })
  .limit(50);
```

### 8. Réactions aux Messages
- Button reactions (👍❤️😂😢😡)
- Ajouter/retirer réaction
- Liste des réactions
- Clic sur réaction pour voir auteur

## Layout Structure

### Desktop (>=1024px)
```
┌──────────────────────────────────────────────────────────────┐
│  Logo [Theme Toggle]        [User]  [+ Nouveau Message]      │
├──────────┬───────────────────────────────────────────────────┤
│          │   Conversation Active                            │
│ Conversa│                                                 │
│ tions    │   ┌─────────────────────────────────────────┐   │
│ [Liste]  │   │ [Groupe]                                 │   │
│          │   │                                          │   │
│ 📧 UserA │   │  ─────────────────────────────────────  │   │
│          │   │  👤 UserA  hier 10:30  Hey!              │   │
│ 📧 GroupX │   │  👤 UserB  hier 10:32  Je vais bien    │   │
│          │   │                                          │   │
│ 👤 UserC │   │  [Input]                                 │   │
│ (online) │   └─────────────────────────────────────────┘   │
└──────────┴───────────────────────────────────────────────────┘
```

### Mobile (<768px)
- Sidebar toggle button (hamburger menu)
- Modal/drawer pour conversations
- Fullscreen pour messages sur mobile

## Stack Technique

- Zustand store: conversations, currentConversation, messages
- ShadCN components: ScrollArea, Input, Button, Avatar, Dialog
- Supabase Realtime
- Tailwind responsive classes

## User Stories

**US-001**: Je veux voir ma liste de conversations triées par dernière activité
**US-002**: Je veux créer une conversation avec un ami spécifique
**US-003**: Je veux créer un groupe avec plusieurs participants
**US-004**: Je veux envoyer des messages à mes amis/groupes
**US-005**: Je veux recevoir des messages en temps réel
**US-006**: Je veux voir le dernier message et timestamp dans la sidebar
**US-007**: Je veux être notifié des nouveaux messages dans cette conversation
**US-008**: Je veux envoyer une réaction à un message existant
**US-009**: Je veux rechercher dans l'historique des messages
