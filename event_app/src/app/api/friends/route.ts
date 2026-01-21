import { createClientComponentClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET() {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { session } } = await supabase.auth.getSession()

    if (!session?.user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    // Récupérer les amis acceptés
    const { data: friendships } = await supabase
      .from('friendships')
      .select(`
        *,
        profiles:user_id(username, avatar_url, last_seen_at, status),
        profiles:friend_id(username, avatar_url, last_seen_at, status)
      `)
      .eq('status', 'accepted')

    if (!friendships) return NextResponse.json({ friends: [] })

    const friends = friendships.map(f => ({
      ...f,
      user: f.user_id === session.user.id ? f.profiles : f.profiles2
    }))

    return NextResponse.json({ friends })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de la récupération des amis' },
      { status: 500 }
    )
  }
}
