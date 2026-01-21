# Authentification - Spécifications

## Vue d'ensemble
Système d'authentification complet avec JWT, profil utilisateur, gestion des sessions.

## Domaines

### 1. User Management
- Créer utilisateur avec email, username, password
- Validation des inputs (email format, username unique)
- Hash password côté serveur
- Profil par défaut créé à l'inscription

### 2. Authentication Flow
- Login avec email/password
- Session persistante avec cookies
- Middleware de protection des routes
- Redirection vers /login si non authentifié

### 3. Security
- Validation Zod côté serveur
- Cookies sécurisés (HttpOnly, SameSite)
- Token JWT rotation
- Protection contre CSRF

## URLs
- `/login` - Page de connexion
- `/register` - Page d'inscription
- `/auth/callback` - Callback OAuth (si ajouté)
