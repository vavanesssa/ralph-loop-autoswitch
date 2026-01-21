-- Migration: Create profiles table
-- Creates a user profiles table linked to auth.users

-- Create profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique,
  avatar_url text,
  status text default 'offline',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create index on username for faster lookups
create index idx_profiles_username on public.profiles(username);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Policy: Allow public read access to profiles
-- This allows fetching profiles by user ID
create policy "Public profiles are viewable by everyone"
  on public.profiles for select
  using (true);

-- Policy: Users can update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Policy: Insert is restricted - only allowed via trigger on signup
create policy "Insert is restricted"
  on public.profiles for insert
  with check (false);

-- Policy: Delete is restricted - only via auth.on_delete cascade
create policy "Delete is restricted"
  on public.profiles for delete
  using (false);
