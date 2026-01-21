import { createClientComponentClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'

export async function GET(request: Request) {
  try {
    const cookieStore = cookies()
    const supabase = createClientComponentClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Non authentifié' }, { status: 401 })
    }

    // Récupérer les conversations
    const { data: conversations, error: conversationsError } = await supabase
      .from('chat_app.conversations')
      .select(`
        *,
        chat_app.conversation_members(*),
        chat_app.messages(
          *,
          profiles:sender_id(username, avatar_url)
        )
      `)
      .order('updated_at', { ascending: false })

    if (conversationsError) throw conversationsError

    return NextResponse.json({ user, conversations })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de la récupération des conversations' },
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

    const { name, type } = await request.json()

    if (!name || !type) {
      return NextResponse.json({ error: 'Nom et type requis' }, { status: 400 })
    }

    const { data: conversation, error } = await supabase
      .from('chat_app.conversations')
      .insert({
        name,
        type,
        created_by: user.id
      })
      .select()
      .single()

    if (error) throw error

    // Ajouter l'utilisateur comme membre admin
    await supabase
      .from('chat_app.conversation_members')
      .insert({
        conversation_id: conversation.id,
        user_id: user.id,
        role: 'admin'
      })

    return NextResponse.json({ conversation })
  } catch (error) {
    return NextResponse.json(
      { error: 'Erreur lors de la création de la conversation' },
      { status: 500 }
    )
  }
}
