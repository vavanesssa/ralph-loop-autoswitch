import { redirect } from 'next/navigation'
import { createClientComponentClient } from '@supabase/ssr'

export default async function Home() {
  const supabase = createClientComponentClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (session) {
    redirect('/chat')
  }

  redirect('/login')
}
