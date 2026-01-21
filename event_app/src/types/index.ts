import { User, Session } from '@supabase/supabase-js';

export type User = {
  id: string;
  email: string;
  username: string;
  avatar_url?: string;
  status?: 'online' | 'away' | 'offline';
  created_at: string;
  updated_at: string;
};

export type Conversation = {
  id: string;
  type: 'private' | 'group';
  name?: string;
  avatar_url?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
  last_message_at?: string;
};

export type ConversationMember = {
  id: string;
  conversation_id: string;
  user_id: string;
  role: 'admin' | 'member';
  joined_at: string;
};

export type Message = {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  updated_at: string;
  sender?: {
    id: string;
    username: string;
    avatar_url?: string;
  };
};

export type Friendship = {
  id: string;
  user_id: string;
  friend_id: string;
  status: 'pending' | 'accepted' | 'declined';
  created_at: string;
  friend?: {
    id: string;
    username: string;
    avatar_url?: string;
    status?: 'online' | 'away' | 'offline';
  };
};

export type Pagination = {
  page: number;
  limit: number;
  total: number;
  hasMore: boolean;
};

export type SortOptions = {
  sortBy?: 'created_at' | 'updated_at';
  sortOrder?: 'asc' | 'desc';
};
