-- Conversation members table
CREATE TABLE IF NOT EXISTS conversation_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('member', 'admin')),
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint (conversation_id, user_id)
CREATE UNIQUE INDEX idx_conversation_members_unique ON conversation_members(conversation_id, user_id);

-- Indexes
CREATE INDEX idx_conversation_members_conversation_id ON conversation_members(conversation_id);
CREATE INDEX idx_conversation_members_user_id ON conversation_members(user_id);
CREATE INDEX idx_conversation_members_role ON conversation_members(role);

-- RLS policies
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

-- Users can view members of conversations they are part of
CREATE POLICY "Users can view conversation members"
ON conversation_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = conversation_members.conversation_id
      AND EXISTS (
        SELECT 1 FROM conversation_members cm2
        WHERE cm2.conversation_id = conversations.id
          AND cm2.user_id = auth.uid()
      )
  )
);

-- Users can join conversations
CREATE POLICY "Users can join conversations"
ON conversation_members FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own role in conversations
CREATE POLICY "Users can update their own role"
ON conversation_members FOR UPDATE
USING (auth.uid() = user_id);

-- Admins can manage conversation members
CREATE POLICY "Admins can manage conversation members"
ON conversation_members FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM conversation_members
    WHERE conversation_members.conversation_id = conversation_members.conversation_id
      AND conversation_members.user_id = auth.uid()
      AND conversation_members.role = 'admin'
  )
);
