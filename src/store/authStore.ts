import { create } from 'zustand'

export interface User {
  id: string
  email: string
  username: string
  avatar_url?: string
}

interface AuthState {
  user: User | null
  session: any | null
  loading: boolean
  setUser: (user: User | null) => void
  setSession: (session: any | null) => void
  setLoading: (loading: boolean) => void
  logout: () => void
}

export const useAuth = create<AuthState>((set) => ({
  user: null,
  session: null,
  loading: true,
  setUser: (user) => set({ user }),
  setSession: (session) => set({ session }),
  setLoading: (loading) => set({ loading }),
  logout: () => set({ user: null, session: null }),
}))
