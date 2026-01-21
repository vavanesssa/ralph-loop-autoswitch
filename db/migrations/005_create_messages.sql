create table public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create index messages_conversation_id_idx on public.messages(conversation_id);
create index messages_user_id_idx on public.messages(user_id);
create index messages_created_at_idx on public.messages(created_at);
