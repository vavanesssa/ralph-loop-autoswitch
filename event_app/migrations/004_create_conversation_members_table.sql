-- Create conversation_members table
CREATE TABLE IF NOT EXISTS public.conversation_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_member UNIQUE (conversation_id, user_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation_id ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user_id ON public.conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_role ON public.conversation_members(role);

-- Enable RLS
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view conversation members if they are in the conversation
CREATE POLICY "Users can view conversation members"
ON public.conversation_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members
    WHERE conversation_id = public.conversation_members.conversation_id
    AND user_id = auth.uid()::uuid
  )
);

-- Policy: Only admins can add members to group conversations
CREATE POLICY "Only admins can add members"
ON public.conversation_members FOR INSERT
WITH CHECK (
  (
    EXISTS (
      SELECT 1 FROM public.conversation_members cm
      WHERE cm.conversation_id = public.conversation_members.conversation_id
      AND cm.user_id = auth.uid()::uuid
      AND cm.role = 'admin'
    )
  )
);

-- Policy: Only admins can remove members
CREATE POLICY "Only admins can remove members"
ON public.conversation_members FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members cm
    WHERE cm.conversation_id = public.conversation_members.conversation_id
    AND cm.user_id = auth.uid()::uuid
    AND cm.role = 'admin'
  )
);

-- Policy: Users can update their own last_read_at
CREATE POLICY "Users can update their own last_read_at"
ON public.conversation_members FOR UPDATE
USING (user_id = auth.uid()::uuid);

-- Function to add member to conversation
CREATE OR REPLACE FUNCTION public.add_member_to_conversation(conversation_id_param UUID, user_id_param UUID, role_param TEXT DEFAULT 'member')
RETURNS TABLE (member_id UUID, success BOOLEAN) AS $$
DECLARE
  member_id_param UUID;
BEGIN
  INSERT INTO public.conversation_members (conversation_id, user_id, role)
  VALUES (conversation_id_param, user_id_param, role_param)
  RETURNING id INTO member_id_param;

  RETURN QUERY SELECT member_id_param, true;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT NULL, false;
END;
$$ LANGUAGE plpgsql;

-- Function to get all members of a conversation
CREATE OR REPLACE FUNCTION public.get_conversation_members(conversation_id_param UUID)
RETURNS TABLE (
  id UUID,
  conversation_id UUID,
  user_id UUID,
  role TEXT,
  joined_at TIMESTAMPTZ,
  profile public.profiles
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cm.id,
    cm.conversation_id,
    cm.user_id,
    cm.role,
    cm.joined_at,
    p
  FROM public.conversation_members cm
  LEFT JOIN public.profiles p ON cm.user_id = p.id
  WHERE cm.conversation_id = conversation_id_param
  ORDER BY cm.role DESC, cm.joined_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
