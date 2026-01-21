import { create } from 'zustand'
import { createClient } from '@/lib/supabase/client'
import type { ChatProfile, ChatConversation, ChatMessage } from '@/types'

interface ConversationsState {
  conversations: ChatConversation[]
  currentConversation: ChatConversation | null
  messages: ChatMessage[]
  loading: boolean
  error: string | null

  loadConversations: () => Promise<void>
  selectConversation: (conversationId: string) => void
  loadMessages: (conversationId: string) => Promise<void>
  sendMessage: (content: string) => Promise<void>
  markAsRead: (conversationId: string) => Promise<void>
}

export const useConversationsStore = create<ConversationsState>((set) => ({
  conversations: [],
  currentConversation: null,
  messages: [],
  loading: false,
  error: null,

  loadConversations: async () => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()

      const { data, error: fetchError } = await supabase
        .from('chat_conversations')
        .select(`
          *,
          chat_conversation_members!inner (
            role
          ),
          chat_profiles!left (
            username,
            avatar_url
          ),
          chat_messages!last (
            content,
            created_at
          )
        `)
        .order('updated_at', { ascending: false })

      if (fetchError) throw fetchError

      set({ conversations: data || [], loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to load conversations', loading: false })
    }
  },

  selectConversation: (conversationId: string) => {
    set((state) => {
      const conversation = state.conversations.find((c) => c.id === conversationId)
      return { currentConversation: conversation || null }
    })
  },

  loadMessages: async (conversationId: string) => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()

      const { data, error: fetchError } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true })

      if (fetchError) throw fetchError

      set({ messages: data || [], loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to load messages', loading: false })
    }
  },

  sendMessage: async (content: string) => {
    if (!content.trim()) return

    set({ loading: true, error: null })
    try {
      const supabase = createClient()

      const { error: insertError } = await supabase.from('chat_messages').insert({
        conversation_id: useConversationsStore.getState().currentConversation?.id,
        content,
      })

      if (insertError) throw insertError

      set({ loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to send message', loading: false })
    }
  },

  markAsRead: async (conversationId: string) => {
    try {
      const supabase = createClient()

      await supabase
        .from('chat_conversation_members')
        .update({ read_at: new Date().toISOString() })
        .eq('conversation_id', conversationId)
        .eq('user_id', (await supabase.auth.getUser()).data.user?.id)
    } catch (error) {
      console.error('Failed to mark as read:', error)
    }
  },
}))
