import { create } from 'zustand'
import { createClient } from '@/lib/supabase/server'
import { User, Session } from '@/types'

interface AuthState {
  user: User | null
  session: Session | null
  loading: boolean
  setUser: (user: User | null) => void
  setSession: (session: Session | null) => void
  logout: () => Promise<void>
  refreshUser: () => Promise<void>
}

export const useAuth = create<AuthState>((set) => ({
  user: null,
  session: null,
  loading: true,
  setUser: (user) => set({ user }),
  setSession: (session) => set({ session }),
  logout: async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    set({ user: null, session: null, loading: false })
  },
  refreshUser: async () => {
    const supabase = createClient()
    const { data: { user, session } } = await supabase.auth.getUser()
    set({ user, session, loading: false })
  },
}))
