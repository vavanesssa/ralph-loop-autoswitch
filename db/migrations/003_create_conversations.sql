create table public.conversations (
  id uuid default gen_random_uuid() primary key,
  type text check (type in ('direct', 'group')) not null,
  name text,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

create index conversations_type_idx on public.conversations(type);
