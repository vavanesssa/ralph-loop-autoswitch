-- Friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint (user_id, friend_id) - ensures bidirectional relationship
CREATE UNIQUE INDEX idx_friendships_unique ON friendships(user_id, friend_id);

-- Indexes for efficient queries
CREATE INDEX idx_friendships_user_id ON friendships(user_id);
CREATE INDEX idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- RLS policies
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Users can view their own friendships and friendships involving them
CREATE POLICY "Users can view their own friendships"
ON friendships FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can insert their own friendship requests
CREATE POLICY "Users can insert their own friendship requests"
ON friendships FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own friendship status (pending/accepted/declined)
CREATE POLICY "Users can update their own friendship status"
ON friendships FOR UPDATE
USING (auth.uid() = user_id OR auth.uid() = friend_id);
