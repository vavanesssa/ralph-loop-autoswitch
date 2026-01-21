-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create composite index for conversation queries
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created_at ON public.messages(conversation_id, created_at DESC);

-- Create index on sender_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages if they are members of the conversation
CREATE POLICY "Users can view messages in conversations they belong to"
ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversation_members
    WHERE conversation_id = public.messages.conversation_id
    AND user_id = auth.uid()::uuid
  )
);

-- Policy: Users can insert messages if they are members of the conversation
CREATE POLICY "Users can insert messages if they are members"
ON public.messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.conversation_members
    WHERE conversation_id = public.messages.conversation_id
    AND user_id = auth.uid()::uuid
  )
);

-- Policy: Users can update their own messages
CREATE POLICY "Users can update their own messages"
ON public.messages FOR UPDATE
USING (sender_id = auth.uid()::uuid);

-- Function to get messages for a conversation
CREATE OR REPLACE FUNCTION public.get_messages(conversation_id_param UUID, limit_param INTEGER DEFAULT 50, offset_param INTEGER DEFAULT 0)
RETURNS TABLE (
  id UUID,
  conversation_id UUID,
  sender_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  sender_profile public.profiles
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id,
    m.conversation_id,
    m.sender_id,
    m.content,
    m.created_at,
    m.updated_at,
    p
  FROM public.messages m
  LEFT JOIN public.profiles p ON m.sender_id = p.id
  WHERE m.conversation_id = conversation_id_param
  ORDER BY m.created_at DESC
  LIMIT limit_param
  OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get paginated messages
CREATE OR REPLACE FUNCTION public.get_paginated_messages(
  conversation_id_param UUID,
  page_param INTEGER DEFAULT 1,
  limit_param INTEGER DEFAULT 50,
  before_message_id_param UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  conversation_id UUID,
  sender_id UUID,
  content TEXT,
  created_at TIMESTAMPTZ,
  sender_profile public.profiles,
  is_newer BOOLEAN
) AS $$
BEGIN
  IF before_message_id_param IS NULL THEN
    RETURN QUERY
    SELECT
      m.id,
      m.conversation_id,
      m.sender_id,
      m.content,
      m.created_at,
      m.updated_at,
      p,
      true as is_newer
    FROM public.messages m
    LEFT JOIN public.profiles p ON m.sender_id = p.id
    WHERE m.conversation_id = conversation_id_param
    ORDER BY m.created_at DESC
    LIMIT limit_param
    OFFSET (page_param - 1) * limit_param;
  ELSE
    RETURN QUERY
    SELECT
      m.id,
      m.conversation_id,
      m.sender_id,
      m.content,
      m.created_at,
      m.updated_at,
      p,
      m.created_at < (
        SELECT created_at
        FROM public.messages
        WHERE id = before_message_id_param
      ) as is_newer
    FROM public.messages m
    LEFT JOIN public.profiles p ON m.sender_id = p.id
    WHERE m.conversation_id = conversation_id_param
      AND m.created_at < (
        SELECT created_at
        FROM public.messages
        WHERE id = before_message_id_param
      )
    ORDER BY m.created_at DESC
    LIMIT limit_param;
  END IF;
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
