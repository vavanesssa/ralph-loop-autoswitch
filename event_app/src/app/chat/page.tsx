import { redirect } from 'next/navigation'
import { createClientComponentClient } from '@supabase/ssr'

export default async function Page() {
  const supabase = createClientComponentClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    redirect('/login')
  }

  // Récupérer les conversations
  const { data: conversations } = await supabase
    .from('chat_app.conversations')
    .select(`
      *,
      chat_app.conversation_members(*)
    `)
    .order('updated_at', { ascending: false })

  return (
    <div className="h-screen flex">
      <div className="w-80 border-r bg-card p-4">
        <h1 className="text-2xl font-bold mb-4">Messages</h1>
        <div className="space-y-2">
          {conversations?.map((conversation) => (
            <div
              key={conversation.id}
              className="p-3 rounded-lg bg-primary/5 hover:bg-primary/10 cursor-pointer transition-colors"
            >
              <div className="font-medium">{conversation.name || 'Conversation'}</div>
              <div className="text-sm text-muted-foreground">
                {conversation.chat_app.conversation_members.length} membres
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex-1 flex flex-col">
        <div className="p-4 border-b">
          <h2 className="text-xl font-semibold">Chat</h2>
        </div>
        <div className="flex-1 p-4">
          <div className="text-center text-muted-foreground">
            Sélectionnez une conversation pour commencer
          </div>
        </div>
      </div>
    </div>
  )
}
