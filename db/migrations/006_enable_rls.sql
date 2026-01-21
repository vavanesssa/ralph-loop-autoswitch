alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

create policy "All users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can view own friendships"
  on public.friendships for select
  using (
    auth.uid() = requester_id
    or auth.uid() = recipient_id
  );

create policy "Users can send friendship requests"
  on public.friendships for insert
  with check (
    auth.uid() = requester_id
    and status = 'pending'
  );

create policy "Users can manage own friendship requests"
  on public.friendships for update
  using (
    auth.uid() = recipient_id
    and status in ('accepted', 'declined')
  );

create policy "Users can delete friendships"
  on public.friendships for delete
  using (
    auth.uid() = requester_id
    or auth.uid() = recipient_id
  );

create policy "Conversation members can view conversation"
  on public.conversations for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = public.conversations.id
      and user_id = auth.uid()
    )
  );

create policy "Authenticated users can create conversations"
  on public.conversations for insert
  with check (
    auth.uid() in (
      select user_id
      from public.conversation_members
      where conversation_id = public.conversations.id
    )
  );

create policy "Members can view conversation members"
  on public.conversation_members for select
  using (
    exists (
      select 1 from public.conversations
      where conversations.id = conversation_members.conversation_id
      and exists (
        select 1 from public.conversation_members cm2
        where cm2.conversation_id = conversations.id
        and cm2.user_id = auth.uid()
      )
    )
  );

create policy "Admins can add members to conversations"
  on public.conversation_members for insert
  with check (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversation_members.conversation_id
      and cm.user_id = auth.uid()
    )
  );

create policy "Conversation members can view messages"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = public.messages.conversation_id
      and user_id = auth.uid()
    )
  );

create policy "Users can send messages in their conversations"
  on public.messages for insert
  with check (
    auth.uid() = user_id
  );

create policy "Users can delete own messages"
  on public.messages for delete
  using (
    auth.uid() = user_id
  );
