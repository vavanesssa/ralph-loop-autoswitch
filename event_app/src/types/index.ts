export interface User {
  id: string;
  username: string;
  avatar_url: string | null;
  status: 'online' | 'offline' | 'away';
  created_at: string;
  updated_at: string;
}

export interface Conversation {
  id: string;
  type: 'private' | 'group';
  name: string | null;
  avatar_url: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface ConversationMember {
  id: string;
  conversation_id: string;
  user_id: string;
  role: 'member' | 'admin';
  joined_at: string;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  updated_at: string | null;
}

export interface Friendship {
  id: string;
  user_id: string;
  friend_id: string;
  status: 'pending' | 'accepted' | 'declined';
  created_at: string;
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: User;
        Insert: Omit<User, 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Omit<User, 'id' | 'created_at' | 'updated_at'>>;
      };
      conversations: {
        Row: Conversation;
        Insert: Omit<Conversation, 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Omit<Conversation, 'id' | 'created_at' | 'updated_at'>>;
      };
      conversation_members: {
        Row: ConversationMember;
        Insert: Omit<ConversationMember, 'id' | 'joined_at'>;
        Update: Partial<Omit<ConversationMember, 'id' | 'joined_at'>>;
      };
      messages: {
        Row: Message;
        Insert: Omit<Message, 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Omit<Message, 'id' | 'created_at' | 'updated_at'>>;
      };
      friendships: {
        Row: Friendship;
        Insert: Omit<Friendship, 'id' | 'created_at'>;
        Update: Partial<Omit<Friendship, 'id' | 'created_at'>>;
      };
    };
  };
}
