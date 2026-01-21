-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 2000),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for efficient query of messages in a conversation
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id_created_at ON messages(conversation_id, created_at DESC);

-- Index for searching messages by sender
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);

-- Index for user's message history
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(sender_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view messages in conversations they are members of
CREATE POLICY "Users can view messages"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversation_members
      WHERE conversation_id = messages.conversation_id
      AND user_id = auth.uid()
    )
  );

-- RLS Policy: Users can send messages (as sender_id)
CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
  );

-- RLS Policy: Users can update their own messages
CREATE POLICY "Users can update their own messages"
  ON messages FOR UPDATE
  USING (
    sender_id = auth.uid()
  );

-- RLS Policy: Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
  ON messages FOR DELETE
  USING (
    sender_id = auth.uid()
  );

-- Trigger for automatic updated_at
CREATE OR REPLACE FUNCTION update_updated_at_messages()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_messages();

-- Trigger to update conversation's last_message_at
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = messages.created_at
  WHERE id = messages.conversation_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversation_last_message_at
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- Trigger to update conversation's last_message_at on message update
CREATE OR REPLACE FUNCTION update_conversation_last_message_on_update()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = messages.updated_at
  WHERE id = messages.conversation_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversation_last_message_at_on_update
  AFTER UPDATE ON messages
  FOR EACH ROW
  WHEN (OLD.content IS DISTINCT FROM NEW.content)
  EXECUTE FUNCTION update_conversation_last_message_on_update();
