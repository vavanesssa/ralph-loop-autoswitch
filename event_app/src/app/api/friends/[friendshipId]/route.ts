import { createClientComponentClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST(
  request: Request,
  { params }: { params: { friendshipId: string } }
) {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { session } } = await supabase.auth.getSession()

    if (!session?.user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    const { action } = await request.json()

    if (action !== 'accept' && action !== 'reject') {
      return NextResponse.json({ error: 'Action invalide' }, { status: 400 })
    }

    // Vérifier que la demande est pour l'utilisateur
    const { data: friendship } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('id', params.friendshipId)
      .single()

    if (!friendship) {
      return NextResponse.json({ error: 'Demande d\'ami non trouvée' }, { status: 404 })
    }

    if (friendship.friend_id !== session.user.id) {
      return NextResponse.json({ error: 'Non autorisé' }, { status: 403 })
    }

    const { error } = await supabase
      .from('friendships')
      .update({ status: action === 'accept' ? 'accepted' : 'rejected' })
      .eq('id', params.friendshipId)

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors du traitement de la demande d\'ami' },
      { status: 500 }
    )
  }
}
