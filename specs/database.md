# Spécifications - Base de Données (Supabase)

## Objectif
Schéma de base de données robuste pour gérer users, conversations, messages, et amis.

## Tables Principales

### 1. profiles
Table d'extension de l'utilisateur Supabase Auth

**Schema:**
```sql
create table public.profiles (
  id uuid references auth.users not null primary key,
  email text not null,
  username text unique not null,
  avatar_url text,
  bio text,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Indexes
create index profiles_username_idx on public.profiles(username);
create index profiles_email_idx on public.profiles(email);
```

**Trigger sur signup:**
```sql
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username)
  values (new.id, new.email, split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql security definer;
```

### 2. friendships
Relation amitié entre deux utilisateurs

**Schema:**
```sql
create table public.friendships (
  id uuid default gen_random_uuid() primary key,
  requester_id uuid references public.profiles(id) not null,
  recipient_id uuid references public.profiles(id) not null,
  status text check (status in ('pending', 'accepted', 'declined')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique(requester_id, recipient_id)
);

-- Indexes
create index friendships_requester_id_idx on public.friendships(requester_id);
create index friendships_recipient_id_idx on public.friendships(recipient_id);
create index friendships_status_idx on public.friendships(status);
```

**Views pour faciliter les queries:**
```sql
create view public.friends_with_status as
select
  f.id as friendship_id,
  f.requester_id,
  f.recipient_id,
  f.status,
  f.created_at,
  p_requester.username as requester_username,
  p_requester.avatar_url as requester_avatar,
  p_recipient.username as recipient_username,
  p_recipient.avatar_url as recipient_avatar
from public.friendships f
left join public.profiles p_requester on f.requester_id = p_requester.id
left join public.profiles p_recipient on f.recipient_id = p_recipient.id;

create view public.pending_friend_requests as
select
  f.id as friendship_id,
  f.requester_id,
  f.recipient_id,
  p_requester.username as requester_username,
  p_requester.avatar_url as requester_avatar,
  p_requester.email as requester_email
from public.friendships f
join public.profiles p_requester on f.requester_id = p_requester.id
where f.status = 'pending' and f.recipient_id = auth.uid();
```

### 3. conversations
Conversations individuelles ou groupales

**Schema:**
```sql
create table public.conversations (
  id uuid default gen_random_uuid() primary key,
  type text check (type in ('direct', 'group')) not null,
  name text, -- Pour les groupes uniquement
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Indexes
create index conversations_type_idx on public.conversations(type);
```

### 4. conversation_members
Liste des participants d'une conversation

**Schema:**
```sql
create table public.conversation_members (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  joined_at timestamp with time zone default timezone('utc'::text, now()),
  unique(conversation_id, user_id)
);

-- Indexes
create index conversation_members_conversation_id_idx on public.conversation_members(conversation_id);
create index conversation_members_user_id_idx on public.conversation_members(user_id);
```

### 5. messages
Contenu des conversations

**Schema:**
```sql
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Indexes
create index messages_conversation_id_idx on public.messages(conversation_id);
create index messages_user_id_idx on public.messages(user_id);
create index messages_created_at_idx on public.messages(created_at);
```

## Relations

```
profiles (1) ---- (N) friendships
profiles (1) ---- (N) conversations (via conversation_members)
profiles (1) ---- (N) messages
conversations (1) ---- (N) conversation_members
conversations (1) ---- (N) messages
```

## RLS Policies

```sql
-- Enable RLS
alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- Profiles: Lectures permission pour tous les utilisateurs authentifiés
create policy "All users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- Friendships: Lectures pour:
-- - Demandeurs en attente de réponse
-- - Acceptés par soi-même
create policy "Users can view own friendships"
  on public.friendships for select
  using (
    auth.uid() = requester_id
    or auth.uid() = recipient_id
  );

-- Friendships: Insertion de demandes
create policy "Users can send friendship requests"
  on public.friendships for insert
  with check (
    auth.uid() = requester_id
    and status = 'pending'
  );

-- Friendships: Acceptation/refus de demande
create policy "Users can manage own friendship requests"
  on public.friendships for update
  using (
    auth.uid() = recipient_id
    and status in ('accepted', 'declined')
  );

-- Friendships: Suppression
create policy "Users can delete friendships"
  on public.friendships for delete
  using (
    auth.uid() = requester_id
    or auth.uid() = recipient_id
  );

-- Conversations: Lectures pour membres
create policy "Conversation members can view conversation"
  on public.conversations for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = public.conversations.id
      and user_id = auth.uid()
    )
  );

-- Conversations: Création (pour le compte)
create policy "Authenticated users can create conversations"
  on public.conversations for insert
  with check (
    auth.uid() in (
      select user_id
      from public.conversation_members
      where conversation_id = public.conversations.id
    )
  );

-- Conversation_members: Lectures
create policy "Members can view conversation members"
  on public.conversation_members for select
  using (
    exists (
      select 1 from public.conversations
      where conversations.id = conversation_members.conversation_id
      and exists (
        select 1 from public.conversation_members cm2
        where cm2.conversation_id = conversations.id
        and cm2.user_id = auth.uid()
      )
    )
  );

-- Conversation_members: Ajout de membres
create policy "Admins can add members to conversations"
  on public.conversation_members for insert
  with check (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversation_members.conversation_id
      and cm.user_id = auth.uid()
    )
  );

-- Messages: Lectures pour membres
create policy "Conversation members can view messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = public.messages.conversation_id
      and user_id = auth.uid()
    )
  );

-- Messages: Création
create policy "Users can send messages in their conversations"
  on public.messages for insert
  with check (
    auth.uid() = user_id
  );

-- Messages: Suppression
create policy "Users can delete own messages"
  on public.messages for delete
  using (
    auth.uid() = user_id
  );
```

## Realtime

- Activer Realtime sur les tables: `messages`, `friendships`
- Écouter les changements pour updates en temps réel
