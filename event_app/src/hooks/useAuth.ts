import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';

export function useAuth() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkUser = async () => {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();

      if (session) {
        setUser(session.user);
      } else {
        router.push('/login');
      }

      setLoading(false);
    };

    checkUser();
  }, [router]);

  const logout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  return { user, loading, logout };
}

// Store pour auth avec Zustand (optionnel)
import { create } from 'zustand';

interface AuthState {
  user: any;
  session: any;
  loading: boolean;
  setUser: (user: any) => void;
  setSession: (session: any) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  session: null,
  loading: true,
  setUser: (user) => set({ user, loading: false }),
  setSession: (session) => set({ session, loading: false }),
  logout: () => set({ user: null, session: null, loading: false }),
}));
