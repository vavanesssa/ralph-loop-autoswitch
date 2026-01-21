-- Create friendships table
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_friendship UNIQUE (user_id, friend_id)
);

-- Create index on user_id and friend_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- Enable RLS
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view friendships they are involved in
CREATE POLICY "Users can view friendships they are involved in"
ON public.friendships FOR SELECT
USING (auth.uid()::uuid = user_id OR auth.uid()::uuid = friend_id);

-- Policy: Users can create friendships
CREATE POLICY "Users can create friendships"
ON public.friendships FOR INSERT
WITH CHECK (auth.uid()::uuid = user_id);

-- Policy: Users can delete their own friendships
CREATE POLICY "Users can delete their own friendships"
ON public.friendships FOR DELETE
USING (auth.uid()::uuid = user_id);

-- Function to get all friends for a user
CREATE OR REPLACE FUNCTION public.get_user_friends(user_id_param UUID)
RETURNS TABLE (
  friendship_id UUID,
  user_id UUID,
  friend_id UUID,
  status TEXT,
  created_at TIMESTAMPTZ,
  friend_profile public.profiles
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.user_id,
    f.friend_id,
    f.status,
    f.created_at,
    p
  FROM public.friendships f
  LEFT JOIN public.profiles p ON f.friend_id = p.id
  WHERE f.user_id = user_id_param
    AND f.status = 'accepted'
    AND p.id IS NOT NULL
  ORDER BY f.created_at DESC;
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
