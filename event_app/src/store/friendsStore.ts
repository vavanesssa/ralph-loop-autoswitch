import { create } from 'zustand'
import { createClient } from '@/lib/supabase/client'
import type { ChatProfile, ChatFriendship } from '@/types'

interface FriendsState {
  friends: ChatProfile[]
  pendingRequests: ChatProfile[]
  friendRequests: ChatProfile[]
  loading: boolean
  error: string | null

  fetchFriends: () => Promise<void>
  acceptFriendRequest: (requesterId: string) => Promise<void>
  declineFriendRequest: (requesterId: string) => Promise<void>
  sendFriendRequest: (recipientId: string) => Promise<void>
}

export const useFriendsStore = create<FriendsState>((set) => ({
  friends: [],
  pendingRequests: [],
  friendRequests: [],
  loading: false,
  error: null,

  fetchFriends: async () => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()
      const userId = (await supabase.auth.getUser()).data.user?.id

      if (!userId) throw new Error('No user authenticated')

      const { data: friendshipsData, error: friendshipsError } = await supabase
        .from('chat_friendships')
        .select(`
          *,
          chat_profiles!chat_friendships_recipient_id_fkey (
            username,
            avatar_url,
            status
          )
        `)
        .or(`user_id.eq.${userId},recipient_id.eq.${userId}`)
        .eq('status', 'accepted')

      if (friendshipsError) throw friendshipsError

      const friends = friendshipsData
        ?.filter((f) => f.user_id === userId)
        .map((f) => f.chat_profiles)
        .flat() || []

      set({ friends, loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to fetch friends', loading: false })
    }
  },

  sendFriendRequest: async (recipientId: string) => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()
      const userId = (await supabase.auth.getUser()).data.user?.id

      if (!userId) throw new Error('No user authenticated')

      const { error: insertError } = await supabase.from('chat_friendships').insert({
        user_id: userId,
        recipient_id: recipientId,
        status: 'pending',
      })

      if (insertError) throw insertError

      set({ loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to send friend request', loading: false })
    }
  },

  acceptFriendRequest: async (requesterId: string) => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()
      const userId = (await supabase.auth.getUser()).data.user?.id

      if (!userId) throw new Error('No user authenticated')

      const { error: updateError } = await supabase
        .from('chat_friendships')
        .update({ status: 'accepted' })
        .eq('recipient_id', userId)
        .eq('user_id', requesterId)

      if (updateError) throw updateError

      await useFriendsStore.getState().fetchFriends()
      set({ loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to accept friend request', loading: false })
    }
  },

  declineFriendRequest: async (requesterId: string) => {
    set({ loading: true, error: null })
    try {
      const supabase = createClient()
      const userId = (await supabase.auth.getUser()).data.user?.id

      if (!userId) throw new Error('No user authenticated')

      const { error: deleteError } = await supabase
        .from('chat_friendships')
        .delete()
        .eq('recipient_id', userId)
        .eq('user_id', requesterId)

      if (deleteError) throw deleteError

      await useFriendsStore.getState().fetchFriends()
      set({ loading: false })
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Failed to decline friend request', loading: false })
    }
  },
}))
