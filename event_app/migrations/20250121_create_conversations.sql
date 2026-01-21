-- Migration: Create conversations table
-- Creates a conversations table for group and private conversations

-- Create conversations table
create table public.conversations (
  id uuid default gen_random_uuid() primary key,
  type text not null check (type in ('private', 'group')),
  name text,
  avatar_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create index on created_at for ordering conversations
create index idx_conversations_created_at on public.conversations(created_at);

-- Enable Row Level Security
alter table public.conversations enable row level security;

-- Policy: Allow read access if user is a member
create policy "Members can view conversations they are part of"
  on public.conversations for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = public.conversations.id and user_id = auth.uid()
    )
  );

-- Policy: Allow insert only for authenticated users
create policy "Authenticated users can create conversations"
  on public.conversations for insert
  with check (auth.uid() = created_by);

-- Policy: Allow update by creator
create policy "Creators can update conversations"
  on public.conversations for update
  using (auth.uid() = created_by);

-- Policy: Allow delete by creator
create policy "Creators can delete conversations"
  on public.conversations for delete
  using (auth.uid() = created_by);
