import { redirect } from 'next/navigation'
import { createClientComponentClient } from '@supabase/ssr'

export default async function Layout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = createClientComponentClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    redirect('/login')
  }

  return <>{children}</>
}
