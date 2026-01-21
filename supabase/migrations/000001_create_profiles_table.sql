-- Create profiles table with RLS
create table if not exists profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique,
  avatar_url text,
  status text default 'online',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create index on username for faster lookups
create index if not exists profiles_username_idx on profiles(username);

-- Enable RLS
alter table profiles enable row level security;

-- Policy: public read access
create policy "Public profiles are viewable by everyone"
  on profiles for select
  using (true);

-- Policy: users can update their own profile
create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);

-- Function to auto-update updated_at
create or replace function updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Trigger on profiles updates
create trigger on_profiles_update
  before update on profiles
  for each row
  execute function updated_at();
