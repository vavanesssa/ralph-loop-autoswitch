-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_conversation_id_created_at ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);

-- RLS policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can view messages in conversations they are members of
CREATE POLICY "Users can view messages"
ON messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM conversation_members
    WHERE conversation_members.conversation_id = messages.conversation_id
      AND conversation_members.user_id = auth.uid()
  )
);

-- Users can insert their own messages
CREATE POLICY "Users can insert messages"
ON messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- Users can update their own messages
CREATE POLICY "Users can update their own messages"
ON messages FOR UPDATE
USING (auth.uid() = sender_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
