import { createClientComponentClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { session } } = await supabase.auth.getSession()

    if (!session?.user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    const { friendId } = await request.json()

    if (!friendId) {
      return NextResponse.json({ error: 'ID ami requis' }, { status: 400 })
    }

    // Vérifier qu'ils ne sont pas déjà amis
    const { data: existingFriendship } = await supabase
      .from('friendships')
      .select('id')
      .eq('user_id', session.user.id)
      .eq('friend_id', friendId)
      .or('status.eq.accepted')
      .single()

    if (existingFriendship) {
      return NextResponse.json({ error: 'Déjà ami' }, { status: 400 })
    }

    // Créer la demande d'ami
    const { error } = await supabase
      .from('friendships')
      .insert({
        user_id: session.user.id,
        friend_id: friendId,
        status: 'pending'
      })

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de l\'envoi de la demande d\'ami' },
      { status: 500 }
    )
  }
}
