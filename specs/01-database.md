# Spécification Base de Données

## Tables Supabase

### profiles
- `id` (uuid, PK, FK → auth.users.id)
- `username` (text, unique, not null)
- `avatar_url` (text, nullable)
- `status` (text, default 'offline') - online/offline/away
- `created_at` (timestamptz, default now())
- `updated_at` (timestamptz, default now())

### friendships
- `id` (uuid, PK, default uuid_generate_v4())
- `user_id` (uuid, FK → profiles.id)
- `friend_id` (uuid, FK → profiles.id)
- `status` (text) - pending/accepted/blocked
- `created_at` (timestamptz, default now())
- Contrainte unique sur (user_id, friend_id)

### conversations
- `id` (uuid, PK, default uuid_generate_v4())
- `type` (text) - private/group
- `name` (text, nullable) - pour les groupes
- `avatar_url` (text, nullable)
- `created_by` (uuid, FK → profiles.id)
- `created_at` (timestamptz, default now())
- `updated_at` (timestamptz, default now())

### conversation_members
- `id` (uuid, PK, default uuid_generate_v4())
- `conversation_id` (uuid, FK → conversations.id)
- `user_id` (uuid, FK → profiles.id)
- `role` (text, default 'member') - admin/member
- `joined_at` (timestamptz, default now())
- Contrainte unique sur (conversation_id, user_id)

### messages
- `id` (uuid, PK, default uuid_generate_v4())
- `conversation_id` (uuid, FK → conversations.id)
- `sender_id` (uuid, FK → profiles.id)
- `content` (text, not null)
- `created_at` (timestamptz, default now())
- `updated_at` (timestamptz, default now())
- Index sur (conversation_id, created_at DESC)

## Row Level Security (RLS)

Toutes les tables auront RLS activé avec policies appropriées:
- profiles: lecture publique, modification propre profil
- friendships: lecture/modification si impliqué
- conversations: accès si membre
- messages: accès si membre de la conversation
