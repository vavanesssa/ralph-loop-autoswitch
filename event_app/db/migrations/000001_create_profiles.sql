-- Create profiles table
create table profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  avatar_url text,
  status text check (status in ('online', 'offline', 'away')) default 'offline',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create index on username
create index idx_profiles_username on profiles(username);

-- Create function to update updated_at timestamp
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Create trigger to update updated_at
create trigger update_profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();

-- Enable Row Level Security
alter table profiles enable row level security;

-- Policy: Public read access for profiles
create policy "Public profiles are viewable by everyone"
  on profiles for select
  using (true);

-- Policy: Users can update their own profile
create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);
