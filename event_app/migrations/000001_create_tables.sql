-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index on username
CREATE INDEX idx_profiles_username ON profiles(username);

-- RLS policies for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- Profiles are created automatically on signup (trigger)
