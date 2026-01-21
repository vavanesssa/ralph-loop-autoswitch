import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { useAuthStore } from "@/store/authStore"
import { useTheme } from "@/hooks/useTheme"
import { LogIn, Mail, Lock, UserPlus } from "lucide-react"
import { useState } from "react"

const registerSchema = {
  email: { type: "string", required: true },
  password: { type: "string", required: true },
  username: { type: "string", required: true, min: 3 }
}

export default function RegisterPage() {
  const { setUser, setSession, isLoading } = useAuthStore()
  const { theme } = useTheme()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [username, setUsername] = useState("")
  const [error, setError] = useState("")
  const [loading, setLoading] = useState(false)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    try {
      setLoading(true)

      const { data: { user }, error: authError } = await supabase.auth.signUp({
        email,
        password
      })

      if (authError) throw authError

      if (user) {
        setUser(user)
        setSession({
          user,
          access_token: "",
          refresh_token: ""
        })
        window.location.href = "/chat"
      }
    } catch (err: any) {
      setError(err.message || "Erreur d'inscription")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <div className="flex items-center justify-center mb-4">
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
              <UserPlus className="w-6 h-6 text-primary" />
            </div>
          </div>
          <CardTitle className="text-2xl text-center">Inscription</CardTitle>
          <CardDescription className="text-center">
            Créez un compte pour accéder au chat
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleRegister} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">
                <UserPlus className="w-4 h-4 inline mr-2" />
                Nom d'utilisateur
              </Label>
              <Input
                id="username"
                type="text"
                placeholder="votre_pseudo"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                minLength={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">
                <Mail className="w-4 h-4 inline mr-2" />
                Email
              </Label>
              <Input
                id="email"
                type="email"
                placeholder="votre@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">
                <Lock className="w-4 h-4 inline mr-2" />
                Mot de passe
              </Label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
              />
            </div>

            {error && (
              <div className="text-sm text-destructive">
                {error}
              </div>
            )}

            <Button
              type="submit"
              className="w-full"
              disabled={loading || isLoading()}
            >
              {loading ? (
                <div className="flex items-center justify-center">
                  <div className="w-4 h-4 border-2 border-current border-r-transparent rounded-full animate-spin mr-2" />
                  Inscription...
                </div>
              ) : (
                <>
                  <UserPlus className="w-4 h-4 inline mr-2" />
                  S'inscrire
                </>
              )}
            </Button>

            <div className="text-center text-sm">
              <span className="text-muted-foreground">
                Déjà un compte ?{" "}
              </span>
              <a href="/login" className="text-primary hover:underline">
                Se connecter
              </a>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}