-- Create conversations table
create table conversations (
  id uuid default gen_random_uuid() primary key,
  type text check (type in ('private', 'group')) not null,
  name text,
  avatar_url text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create index on created_at for ordering
create index idx_conversations_created_at on conversations(created_at desc);

-- Create index on type for filtering
create index idx_conversations_type on conversations(type);

-- Create function to update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Create trigger to update updated_at
create trigger update_conversations_updated_at
  before update on conversations
  for each row
  execute function update_updated_at_column();

-- Enable Row Level Security
alter table conversations enable row level security;

-- Policy: Users can view all conversations they are members of
create policy "Users can view all conversations they are members of"
  on conversations for select
  using (
    id in (
      select conversation_id
      from conversation_members
      where user_id = auth.uid()
    )
  );

-- Policy: Users can create conversations
create policy "Users can create conversations"
  on conversations for insert
  with check (
    created_by = auth.uid()
  );

-- Policy: Conversation creators can update their conversations
create policy "Conversation creators can update their conversations"
  on conversations for update
  using (
    created_by = auth.uid()
  );
