# Plan d'implémentation

## Phase 1: Setup & Infrastructure

### 1. [ ] Créer le projet Next.js
- `npx create-next-app@latest event_app`
- TypeScript, Tailwind, App Router, src/

### 2. [ ] Installer les dépendances
- ShadCN/UI init
- Supabase client
- Zod, Zustand, next-themes

### 3. [ ] Configurer Supabase
- Variables d'environnement
- Client Supabase côté serveur et client

### 4. [ ] Setup base de données Supabase
- Créer tables: profiles, friendships, conversations, conversation_members, messages
- Activer RLS
- Créer policies de sécurité
- Trigger pour créer profil après signup

## Phase 2: Authentification

### 5. [ ] Installer composants ShadCN auth
- Button, Input, Card, Label, Toast

### 6. [ ] Page Login
- Route /login
- Formulaire avec validation Zod
- Intégration Supabase Auth

### 7. [ ] Page Register
- Route /register
- Formulaire avec username, email, password
- Validation Zod

### 8. [ ] Middleware protection routes
- Protéger /chat/*
- Redirection automatique

### 9. [ ] Layout authentifié
- Header avec user menu
- Bouton déconnexion

## Phase 3: UI Core

### 10. [ ] Setup thème dark/light
- next-themes provider
- Toggle dans header
- Persistence localStorage

### 11. [ ] Layout principal chat
- Sidebar conversations
- Zone messages principale
- Responsive (drawer mobile)

### 12. [ ] Composants ShadCN UI
- Avatar, Badge, ScrollArea, Dialog
- DropdownMenu, Tabs, Skeleton

## Phase 4: Chat Base

### 13. [ ] Store Zustand conversations
- État: conversations, current, messages
- Actions: select, load, send

### 14. [ ] Liste conversations
- Affichage dans sidebar
- Dernier message preview
- Badge non-lu

### 15. [ ] Affichage messages
- Messages groupés par date
- Avatar + username + timestamp
- Scroll auto vers bas

### 16. [ ] Envoi messages
- Input avec bouton
- Enter pour envoyer
- Validation

### 17. [ ] Realtime messages
- Supabase Realtime subscription
- Nouveaux messages en temps réel

## Phase 5: Conversations

### 18. [ ] Création conversation privée
- Dialog de sélection utilisateur
- Création en DB

### 19. [ ] Création groupe
- Dialog avec nom + membres
- Sélection multiple utilisateurs

### 20. [ ] Gestion groupe (admin)
- Ajouter/retirer membres
- Modifier nom/avatar

## Phase 6: Amis

### 21. [ ] Recherche utilisateurs
- Input recherche
- Résultats avec bouton ajouter

### 22. [ ] Demandes d'amitié
- Envoyer demande
- Badge notification

### 23. [ ] Liste amis
- Affichage amis acceptés
- Statut online/offline
- Actions rapides

### 24. [ ] Gestion demandes
- Accepter/refuser demandes
- Liste demandes en attente

## Phase 7: Fonctionnalités avancées

### 25. [ ] Recherche messages
- Input recherche globale
- Filtrage par conversation
- Highlight résultats

### 26. [ ] Pagination messages
- Infinite scroll
- Charger anciens messages

### 27. [ ] Statut utilisateur
- Online/offline/away
- Presence Supabase

## Phase 8: Finalisation

### 28. [ ] Tests et bugfix
- Tester tous les flux
- Corriger bugs

### 29. [ ] Build production
- `npm run build`
- Fix erreurs TypeScript/lint

### 30. [ ] Déploiement Vercel
- Configurer variables env
- Deploy et test prod
