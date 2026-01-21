import { createClientComponentClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'

export async function GET(
  request: Request,
  { params }: { params: { conversationId: string } }
) {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    // Vérifier que l'utilisateur est membre de la conversation
    const { data: member } = await supabase
      .from('chat_app.conversation_members')
      .select('role')
      .eq('conversation_id', params.conversationId)
      .eq('user_id', user.id)
      .single()

    if (!member) {
      return NextResponse.json({ error: 'Accès refusé' }, { status: 403 })
    }

    // Récupérer les messages
    const { data: messages, error } = await supabase
      .from('chat_app.messages')
      .select(`
        *,
        profiles:sender_id(username, avatar_url)
      `)
      .eq('conversation_id', params.conversationId)
      .order('created_at', { ascending: true })

    if (error) throw error

    return NextResponse.json({ messages })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de la récupération des messages' },
      { status: 500 }
    )
  }
}

export async function POST(request: Request) {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    const { conversationId, content } = await request.json()

    if (!conversationId || !content) {
      return NextResponse.json({ error: 'Conversation et contenu requis' }, { status: 400 })
    }

    // Vérifier que l'utilisateur est membre de la conversation
    const { data: member } = await supabase
      .from('chat_app.conversation_members')
      .select('role')
      .eq('conversation_id', conversationId)
      .eq('user_id', user.id)
      .single()

    if (!member) {
      return NextResponse.json({ error: 'Accès refusé' }, { status: 403 })
    }

    const { data: message, error } = await supabase
      .from('chat_app.messages')
      .insert({
        conversation_id: conversationId,
        sender_id: user.id,
        content
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ message })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de l\'envoi du message' },
      { status: 500 }
    )
  }
}
