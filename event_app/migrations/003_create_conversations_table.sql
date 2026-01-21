-- Create conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('private', 'group')),
  name TEXT,
  avatar_url TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON public.conversations(created_at DESC);

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view conversations they are members of
CREATE POLICY "Users can view conversations they are members of"
ON public.conversations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members
    WHERE conversation_id = public.conversations.id
    AND user_id = auth.uid()::uuid
  )
);

-- Policy: Users can create conversations
CREATE POLICY "Users can create conversations"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid()::uuid = created_by);

-- Policy: Only creator can update conversation info
CREATE POLICY "Only creator can update conversation"
ON public.conversations FOR UPDATE
USING (auth.uid()::uuid = created_by);

-- Function to get conversation info with last message
CREATE OR REPLACE FUNCTION public.get_conversation_with_last_message(conversation_id_param UUID)
RETURNS TABLE (
  conversation_id UUID,
  conversation_type TEXT,
  conversation_name TEXT,
  avatar_url TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ,
  last_message_id UUID,
  last_message_content TEXT,
  last_message_sender_id UUID,
  last_message_created_at TIMESTAMPTZ,
  unread_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id as conversation_id,
    c.type as conversation_type,
    c.name as conversation_name,
    c.avatar_url,
    c.created_by,
    c.created_at,
    lm.id as last_message_id,
    lm.content as last_message_content,
    lm.sender_id as last_message_sender_id,
    lm.created_at as last_message_created_at,
    COALESCE(cm.unread_count, 0) as unread_count
  FROM public.conversations c
  LEFT JOIN LATERAL (
    SELECT id, content, sender_id, created_at
    FROM public.messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) lm ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) as unread_count
    FROM public.conversation_members cm
    WHERE cm.conversation_id = c.id
    AND cm.user_id = auth.uid()::uuid
    AND EXISTS (
      SELECT 1 FROM public.messages m
      WHERE m.conversation_id = c.id
      AND m.created_at > cm.last_read_at
      AND m.sender_id != auth.uid()::uuid
    )
  ) cm ON true
  WHERE c.id = conversation_id_param;
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
