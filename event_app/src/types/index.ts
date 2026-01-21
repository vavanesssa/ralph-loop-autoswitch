export interface User {
  id: string
  username: string
  avatar_url?: string
  status: 'online' | 'away' | 'offline'
  created_at: string
  updated_at: string
}

export interface Conversation {
  id: string
  type: 'private' | 'group'
  name?: string
  avatar_url?: string
  created_by: string
  created_at: string
  updated_at: string
}

export interface ConversationMember {
  id: string
  conversation_id: string
  user_id: string
  role: 'admin' | 'member'
  joined_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  content: string
  created_at: string
  updated_at?: string
}

export interface Friendship {
  id: string
  user_id: string
  friend_id: string
  status: 'pending' | 'accepted' | 'rejected'
  created_at: string
}

export interface MessageWithUser extends Message {
  user?: {
    id: string
    username: string
    avatar_url?: string
  }
}

export interface ConversationWithMembers extends Conversation {
  members?: ConversationMember[]
  last_message?: {
    id: string
    content: string
    created_at: string
  }
}
