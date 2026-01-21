create table public.friendships (
  id uuid default gen_random_uuid() primary key,
  requester_id uuid references public.profiles(id) not null,
  recipient_id uuid references public.profiles(id) not null,
  status text check (status in ('pending', 'accepted', 'declined')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique(requester_id, recipient_id)
);

create index friendships_requester_id_idx on public.friendships(requester_id);
create index friendships_recipient_id_idx on public.friendships(recipient_id);
create index friendships_status_idx on public.friendships(status);

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

create trigger on_friendships_updated
  before update on public.friendships
  for each row execute procedure public.handle_updated_at();
