-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('private', 'group')),
  name TEXT,
  avatar_url TEXT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX idx_conversations_type ON conversations(type);

-- RLS policies
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Users can view conversations they are members of
CREATE POLICY "Users can view conversations they are members of"
ON conversations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversation_members
    WHERE conversation_members.conversation_id = conversations.id
      AND conversation_members.user_id = auth.uid()
  )
);

-- Users can insert their own conversations
CREATE POLICY "Users can insert their own conversations"
ON conversations FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- Users can update their own conversations
CREATE POLICY "Users can update their own conversations"
ON conversations FOR UPDATE
USING (auth.uid() = created_by);
