-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Unique constraint: each pair of users can only have one friendship request
CREATE UNIQUE INDEX IF NOT EXISTS idx_friendships_user_friend ON friendships(user_id, friend_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_friendships_friend_user ON friendships(friend_id, user_id);

-- Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- Enable Row Level Security
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own friendships and friendships with them
CREATE POLICY "Users can view their friendships"
  ON friendships FOR SELECT
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- RLS Policy: Users can update only their side of the friendship
CREATE POLICY "Users can update their friendship requests"
  ON friendships FOR UPDATE
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- RLS Policy: Users can insert their own friendship requests
CREATE POLICY "Users can insert friendship requests"
  ON friendships FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    friend_id != auth.uid()
  );

-- RLS Policy: Users can delete their friendship requests
CREATE POLICY "Users can delete friendship requests"
  ON friendships FOR DELETE
  USING (
    user_id = auth.uid() OR friend_id = auth.uid()
  );

-- Trigger for automatic updated_at
CREATE OR REPLACE FUNCTION update_updated_at_friendships()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_friendships_updated_at
  BEFORE UPDATE ON friendships
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_friendships();
