"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { createClientComponentClient } from "@supabase/ssr"
import { 
  LogOut, 
  Settings, 
  MessageSquare, 
  User,
  Menu,
  X
} from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ScrollArea } from "@/components/ui/scroll-area"

export function Header() {
  const router = useRouter()
  const supabase = createClientComponentClient()
  const [isOpen, setIsOpen] = useState(false)
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchUser()
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user || null)
    })

    return () => subscription.unsubscribe()
  }, [])

  const fetchUser = async () => {
    const { data: { session } } = await supabase.auth.getSession()
    setUser(session?.user || null)
    setLoading(false)
  }

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    setIsOpen(false)
  }

  if (loading) return null

  const initial = user?.user_metadata?.username?.[0] || user?.email?.[0] || '?'
  const username = user?.user_metadata?.username || user?.email?.split('@')[0] || 'Utilisateur'

  return (
    <>
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden"
              onClick={() => setIsOpen(!isOpen)}
            >
              {isOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </Button>
            <div className="flex items-center gap-2">
              <MessageSquare className="h-6 w-6 text-primary" />
              <span className="text-xl font-bold hidden sm:block">EventChat</span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="gap-2">
                  <Avatar className="h-8 w-8">
                    <AvatarImage src={user?.user_metadata?.avatar_url} />
                    <AvatarFallback>{initial}</AvatarFallback>
                  </Avatar>
                  <span className="hidden md:inline">{username}</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuLabel>
                  <div className="flex flex-col space-y-1">
                    <p className="text-sm font-medium">{username}</p>
                    <p className="text-xs text-muted-foreground">{user?.email}</p>
                  </div>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => router.push('/chat')}>
                  <MessageSquare className="h-4 w-4 mr-2" />
                  Discussions
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => router.push('/settings')}>
                  <Settings className="h-4 w-4 mr-2" />
                  Paramètres
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleLogout} className="text-destructive">
                  <LogOut className="h-4 w-4 mr-2" />
                  Déconnexion
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </header>

      {isOpen && (
        <div className="fixed inset-0 bg-background/80 backdrop-blur-sm z-40 md:hidden">
          <div className="p-4">
            <Button
              variant="ghost"
              size="icon"
              className="absolute top-4 right-4"
              onClick={() => setIsOpen(false)}
            >
              <X className="h-5 w-5" />
            </Button>
            <div className="mt-16 space-y-2">
              <Button variant="ghost" className="w-full justify-start" onClick={() => router.push('/chat')}>
                <MessageSquare className="h-4 w-4 mr-2" />
                Discussions
              </Button>
              <Button variant="ghost" className="w-full justify-start" onClick={() => router.push('/settings')}>
                <Settings className="h-4 w-4 mr-2" />
                Paramètres
              </Button>
              <Button variant="ghost" className="w-full justify-start text-destructive" onClick={handleLogout}>
                <LogOut className="h-4 w-4 mr-2" />
                Déconnexion
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}