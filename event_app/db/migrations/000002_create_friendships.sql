-- Create friendships table
create table friendships (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  status text check (status in ('pending', 'accepted', 'declined')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create unique constraint on (user_id, friend_id) to prevent duplicate requests
create unique index idx_friendships_unique_user_friend on friendships(user_id, friend_id);

-- Create indexes on user_id and friend_id for faster queries
create index idx_friendships_user_id on friendships(user_id);
create index idx_friendships_friend_id on friendships(friend_id);

-- Create function to get friendships both ways
create or replace function get_all_friendships(user_id_param uuid)
returns table(
  id uuid,
  user_id uuid,
  friend_id uuid,
  status text,
  created_at timestamp with time zone
) as $$
begin
  return query
  select
    f.id,
    f.user_id,
    f.friend_id,
    f.status,
    f.created_at
  from friendships f
  where f.user_id = user_id_param
     or f.friend_id = user_id_param;
end;
$$ language plpgsql;

-- Enable Row Level Security
alter table friendships enable row level security;

-- Policy: Users can see all their friendships
create policy "Users can view all their friendships"
  on friendships for select
  using (
    user_id = auth.uid() or friend_id = auth.uid()
  );

-- Policy: Users can insert their own friendship requests
create policy "Users can create their own friendship requests"
  on friendships for insert
  with check (
    user_id = auth.uid()
  );

-- Policy: Users can update their friendship status
create policy "Users can update their own friendship status"
  on friendships for update
  using (
    user_id = auth.uid() or friend_id = auth.uid()
  );

-- Policy: Users can delete their own friendships
create policy "Users can delete their own friendships"
  on friendships for delete
  using (
    user_id = auth.uid() or friend_id = auth.uid()
  );
