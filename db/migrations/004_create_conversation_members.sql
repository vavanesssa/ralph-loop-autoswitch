create table public.conversation_members (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  joined_at timestamp with time zone default timezone('utc'::text, now()),
  unique(conversation_id, user_id)
);

create index conversation_members_conversation_id_idx on public.conversation_members(conversation_id);
create index conversation_members_user_id_idx on public.conversation_members(user_id);
