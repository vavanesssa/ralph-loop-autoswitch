export interface User {
  id: string
  email: string
  username: string
  avatar_url?: string
  bio?: string
  created_at: string
  updated_at: string
}

export interface Friendship {
  id: string
  requester_id: string
  recipient_id: string
  status: 'pending' | 'accepted' | 'declined'
  created_at: string
  updated_at: string
}

export interface Conversation {
  id: string
  type: 'direct' | 'group'
  name?: string
  created_at: string
  updated_at: string
}

export interface ConversationMember {
  id: string
  conversation_id: string
  user_id: string
  role: string
  joined_at: string
}

export interface Message {
  id: string
  conversation_id: string
  user_id: string
  content: string
  created_at: string
}

export interface ConversationWithMembers extends Conversation {
  members: ConversationMember[]
  unread_count: number
  last_message?: Message
  last_message_at?: string
  other_users?: User[]
}

export interface MessageWithUser extends Message {
  user: User
}
