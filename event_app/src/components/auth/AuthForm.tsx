"use client"

import { useState, FormEvent } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"

const authSchema = z.object({
  email: z.string().email("Email invalide"),
  password: z.string().min(6, "Le mot de passe doit contenir au moins 6 caractères"),
})

interface AuthFormProps {
  type: "login" | "register"
  onSubmit: (data: { email: string; password: string; username?: string }) => Promise<void>
  loading?: boolean
  error?: string
}

export function AuthForm({ type, onSubmit, loading, error }: AuthFormProps) {
  const [localError, setLocalError] = useState<string>("")
  const { register, handleSubmit, formState: { errors } } = useForm<z.infer<typeof authSchema>>({
    resolver: zodResolver(authSchema),
  })

  const handleSubmitWithUsername = handleSubmit(async (data) => {
    try {
      setLocalError("")
      if (type === "register") {
        await onSubmit({ ...data, username: "user" })
      } else {
        await onSubmit({ ...data })
      }
    } catch (err) {
      setLocalError(err instanceof Error ? err.message : "Une erreur est survenue")
    }
  })

  return (
    <Card className="w-full max-w-md">
      <CardHeader>
        <CardTitle>{type === "login" ? "Connexion" : "Inscription"}</CardTitle>
        <CardDescription>
          {type === "login"
            ? "Entrez vos identifiants pour vous connecter"
            : "Créez un compte pour commencer"}
        </CardDescription>
      </CardHeader>
      <form onSubmit={handleSubmitWithUsername}>
        <CardContent className="space-y-4">
          {error && <div className="text-sm text-red-500">{error}</div>}
          {localError && <div className="text-sm text-red-500">{localError}</div>}

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              placeholder="vous@email.com"
              {...register("email")}
              disabled={loading}
            />
            {errors.email && <p className="text-sm text-red-500">{errors.email.message}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="password">Mot de passe</Label>
            <Input
              id="password"
              type="password"
              placeholder="••••••••"
              {...register("password")}
              disabled={loading}
            />
            {errors.password && <p className="text-sm text-red-500">{errors.password.message}</p>}
          </div>
        </CardContent>
        <CardFooter>
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? "Chargement..." : type === "login" ? "Se connecter" : "S'inscrire"}
          </Button>
        </CardFooter>
      </form>
    </Card>
  )
}