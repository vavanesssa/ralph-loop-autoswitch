-- Migration: Create friendships table
-- Creates a friendship relationship table between users

-- Create friendships table
create table public.friendships (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create unique constraint on (user_id, friend_id) to prevent duplicate friendships
create unique index idx_friendships_user_friend on public.friendships(user_id, friend_id);

-- Create indexes on user_id and friend_id for faster lookups
create index idx_friendships_user_id on public.friendships(user_id);
create index idx_friendships_friend_id on public.friendships(friend_id);
create index idx_friendships_status on public.friendships(status);

-- Enable Row Level Security
alter table public.friendships enable row level security;

-- Policy: Allow read access if user is involved in the friendship
create policy "Users can view friendships they are part of"
  on public.friendships for select
  using (auth.uid() = user_id or auth.uid() = friend_id);

-- Policy: Allow insert of pending friendships
create policy "Users can send friend requests"
  on public.friendships for insert
  with check (
    auth.uid() = user_id and
    status = 'pending'
  );

-- Policy: Allow updating only the status
create policy "Users can update friendship status"
  on public.friendships for update
  using (
    (auth.uid() = user_id and status = 'pending') or
    (auth.uid() = friend_id and status = 'pending')
  );

-- Policy: Allow delete if user is part of the friendship
create policy "Users can delete friendships they are part of"
  on public.friendships for delete
  using (auth.uid() = user_id or auth.uid() = friend_id);
