# Spécification Authentification

## Provider

Supabase Auth avec:
- Email/Password
- OAuth optionnel (Google, GitHub)

## Flux

### Inscription
1. Formulaire: email, password, username
2. Validation Zod côté client
3. `supabase.auth.signUp()`
4. Création automatique du profil via trigger DB
5. Redirection vers /chat

### Connexion
1. Formulaire: email, password
2. Validation Zod
3. `supabase.auth.signInWithPassword()`
4. Redirection vers /chat

### Déconnexion
1. `supabase.auth.signOut()`
2. Redirection vers /login

## Pages

- `/login` - Connexion
- `/register` - Inscription
- `/` - Redirection vers /chat si connecté, sinon /login

## Protection des routes

Middleware Next.js pour protéger /chat/*
