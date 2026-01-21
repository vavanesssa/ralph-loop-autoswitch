-- Create conversation_members table
CREATE TABLE IF NOT EXISTS conversation_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'member', 'owner')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Unique constraint: one user per conversation
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversation_members_conversation_user ON conversation_members(conversation_id, user_id);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_conversation_members_conversation_id ON conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_user_id ON conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_members_role ON conversation_members(role);

-- Enable Row Level Security
ALTER TABLE conversation_members ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view members of conversations they are in
CREATE POLICY "Users can view conversation members"
  ON conversation_members FOR SELECT
  USING (
    user_id = auth.uid()
  );

-- RLS Policy: Users can insert as members of conversations they create
CREATE POLICY "Users can add members to conversations they created"
  ON conversation_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_members.conversation_id
      AND created_by = auth.uid()
    )
  );

-- RLS Policy: Users can update their own role (for admin/owner management)
CREATE POLICY "Users can update conversation member roles"
  ON conversation_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_members.conversation_id
      AND created_by = auth.uid()
    )
  );

-- RLS Policy: Users can remove members from conversations they created
CREATE POLICY "Users can remove members from conversations they created"
  ON conversation_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE id = conversation_members.conversation_id
      AND created_by = auth.uid()
    )
  );
