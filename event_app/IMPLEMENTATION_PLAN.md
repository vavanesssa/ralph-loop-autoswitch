# Plan d'implémentation
[APPROVED]

## Phase 1: Setup & Infrastructure (30 min)

### 1. [DONE] Initialiser projet Next.js avec TypeScript et Tailwind
- Exécuter `npx create-next-app@latest event_app`
- Sélectionner: TypeScript, Tailwind CSS, App Router, src/ directory
- Créer dossier `src/` avec `/app`, `/components`, `/lib`, `/types`, `/store`

### 2. [DONE] Installer dépendances base
- `npm install -D @types/node @types/react @types/react-dom`
- `npm install next-themes class-variance-authority clsx tailwind-merge lucide-react`
- `npm install -D tailwindcss postcss autoprefixer`

### 3. [DONE] Configurer Tailwind CSS et thème
- Vérifier `tailwind.config.ts` (clsx/tailwind-merge)
- Configurer couleurs de thème dans `tailwind.config.ts`
- Tester thème dark/light

### 4. [DONE] Installer dépendances Supabase et UI
- `npm install @supabase/supabase-js @supabase/ssr zod zustand`
- Initialiser ShadCN UI: `npx shadcn@latest init`
- Installer composants ShadCN: button, input, card, label, avatar, badge, dialog, dropdown-menu, scroll-area, tabs, skeleton, toast, separator

### 5. [DONE] Configurer variables d'environnement
- Créer `.env.local` avec:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY` (optionnel)
- Créer fichier `.env.example`

### 6. [DONE] Créer client Supabase côté client et serveur
- `src/lib/supabase/client.ts`
- `src/lib/supabase/server.ts`
- `src/lib/supabase/middleware.ts`

### 7. [DONE] Créer types TypeScript
- `src/types/index.ts`: User, Conversation, Message, Friendship, ConversationMember
- Types dérivés des specs

### 8. [DONE] Créer hooks utilitaires
- `src/hooks/useTheme.ts`: next-themes
- `src/hooks/useAuth.ts`: gestion auth Supabase

## Phase 2: Base de données Supabase (45 min)

### 9. [DONE] Créer migration tables profiles
- SQL: créer table profiles avec colonnes id, username, avatar_url, status, created_at, updated_at
- Index sur username
- Activer RLS avec policy de lecture publique et modification propre

### 10. [DONE] Créer migration tables friendships
- SQL: créer table friendships avec id, user_id, friend_id, status, created_at
- Contrainte unique sur (user_id, friend_id)
- Index sur user_id et friend_id
- Activer RLS: lecture si impliqué, modification de son côté

### 11. [DONE] Créer migration tables conversations
- SQL: créer table conversations avec id, type, name, avatar_url, created_by, created_at, updated_at
- Index sur created_at
- Activer RLS: lecture si membre, modification par créateur/admin

### 12. [DONE] Créer migration tables conversation_members
- SQL: créer table conversation_members avec id, conversation_id, user_id, role, joined_at
- Contrainte unique sur (conversation_id, user_id)
- Index sur conversation_id, user_id, role
- Activer RLS: lecture si membre, modification par admin

### 13. [DONE] Créer migration tables messages
- SQL: créer table messages avec id, conversation_id, sender_id, content, created_at, updated_at
- Index sur (conversation_id, created_at DESC)
- Activer RLS: lecture si membre, insertion si sender_id membre

### 14. [DONE] Créer triggers et fonctions
- Trigger: création profil auto après signup dans auth.users
- Fonction: updated_at automatique
- Index pour performances

### 15. [DONE] Tester base de données
- Vérifier tables existent avec `supabase db dump`
- Tester RLS policies
- Vérifier triggers

### 9. [DONE] Créer migration tables profiles
- SQL: créer table profiles avec colonnes id, username, avatar_url, status, created_at, updated_at
- Index sur username
- Activer RLS avec policy de lecture publique et modification propre

### 10. [DONE] Créer migration tables friendships
- SQL: créer table friendships avec id, user_id, friend_id, status, created_at
- Contrainte unique sur (user_id, friend_id)
- Index sur user_id et friend_id
- Activer RLS: lecture si impliqué, modification de son côté

### 11. [DONE] Créer migration tables conversations
- SQL: créer table conversations avec id, type, name, avatar_url, created_by, created_at, updated_at
- Index sur created_at
- Activer RLS: lecture si membre, modification par créateur/admin

### 12. [DONE] Créer migration tables conversation_members
- SQL: créer table conversation_members avec id, conversation_id, user_id, role, joined_at
- Contrainte unique sur (conversation_id, user_id)
- Index sur conversation_id, user_id, role
- Activer RLS: lecture si membre, modification par admin

### 13. [DONE] Créer migration tables messages
- SQL: créer table messages avec id, conversation_id, sender_id, content, created_at, updated_at
- Index sur (conversation_id, created_at DESC)
- Activer RLS: lecture si membre, insertion si sender_id membre

## Phase 3: Authentification (60 min)

### 16. [ ] Créer composants ShadCN auth
- Button, Input, Label, Card (déjà installés, vérifier configuration)
- Custom Input avec label

### 17. [ ] Créer composant Form/AuthForm
- Validation Zod côté client
- État loading
- Gestion erreurs feedback

### 18. [ ] Page de login /login
- Créer dossier `src/app/login`
- Créer page `page.tsx`
- Intégrer formulaire email/password
- Validation Zod: email format, password >= 6 caractères
- Intégration Supabase Auth.signInWithPassword()
- Redirection vers /chat si succès

### 19. [ ] Page d'inscription /register
- Créer dossier `src/app/register`
- Créer page `page.tsx`
- Formulaire email, password, username
- Validation Zod: username unique, email valide, password >= 6
- Supabase Auth.signUp()
- Redirection vers /chat si succès

### 20. [ ] Middleware de protection des routes
- Créer `src/middleware.ts`
- Protéger /chat/*
- Redirection vers /login si non authentifié
- Redirection vers /chat si déjà authentifié

### 21. [ ] Layout authentifié avec header
- Créer `src/app/chat/layout.tsx`
- Header avec: logo, user menu déroulant
- Bouton déconnexion
- Composant UserMenu: avatar, username, déconnexion
- Temps réel: user status

### 22. [ ] Setup theme provider
- Créer `src/components/theme-provider.tsx`
- next-themes Provider avec HTMLAttributes
- Tester toggle dark/light

## Phase 4: UI Core (45 min)

### 23. [ ] Layout principal chat
- Créer `src/app/chat/layout.tsx`
- Sidebar gauche: conversations
- Zone centrale: messages
- Responsive: mobile drawer sidebar

### 24. [ ] Créer composants UI utilitaires
- `src/components/ui/avatar.tsx`
- `src/components/ui/badge.tsx`
- `src/components/ui/scroll-area.tsx`
- `src/components/ui/skeleton.tsx`
- `src/components/ui/toast.tsx`

### 25. [ ] Sidebar conversations
- Composant `ConversationSidebar`
- Liste conversations avec preview message
- Badge non-lu
- Compteur notifications
- Click pour sélectionner
- Compteur messages non-lus

### 26. [ ] Zone messages
- Composant `MessageArea`
- Zone de messages scrollable
- Zone input en bas
- Scroll auto vers bas

### 27. [ ] Input messages
- Composant `MessageInput`
- Input texte
- Bouton envoyer
- Raccourcis: Enter=envoyer, Shift+Enter=nouvelle ligne
- Validation: non vide, max 2000 caractères
- Preview avatar utilisateur

### 28. [ ] Composant message individuel
- `src/components/chat/Message.tsx`
- Avatar + username
- Contenu texte
- Horodatage relatif
- Actions: reply, more options

### 29. [ ] Grille messages par date
- Composant `MessageGroup.tsx`
- Groupement par date (aujourd'hui, hier, date spécifique)
- Indicateur de groupe

## Phase 5: Store Zustand (45 min)

### 30. [ ] Store conversations Zustand
- Créer `src/store/conversationsStore.ts`
- État: conversations, currentConversation, messages, loading
- Actions: selectConversation, loadConversations, sendMessage, markAsRead
- Persistence: pas nécessaire

### 31. [ ] Store auth Zustand (optionnel, peut utiliser Supabase)
- Créer `src/store/authStore.ts`
- État: user, session, loading
- Actions: setUser, setSession, logout

### 32. [ ] Store friends Zustand
- Créer `src/store/friendsStore.ts`
- État: friends, pendingRequests, friendsRequests
- Actions: fetchFriends, acceptFriend, sendFriendRequest

## Phase 6: Chat Base (90 min)

### 33. [ ] Composant ConversationSidebar
- Intégrer store Zustand
- Fetch conversations avec Supabase
- Affichage liste
- Loading skeleton
- Error handling

### 34. [ ] Composant MessageArea
- Intégrer store Zustand
- Render messages
- Scroll auto vers bas
- Scroll vers haut pour charger plus
- Groupement par date

### 35. [ ] Composant MessageInput
- Intégrer store Zustand
- Input avec validation
- Envoi message (POST à Supabase)
- Optimistic UI update
- Erreur handling

### 36. [ ] Realtime messages
- Subscription Supabase Realtime sur messages
- Écouter new INSERT
- Update store Zustand
- Toast notification
- Séparer localStorage pour préload historique

### 37. [ ] Pagination messages
- Composant `MessagePagination`
- LoadMoreButton en haut
- Charger 50 messages par page
- Optimistic loading
- Loading skeleton

### 38. [ ] Liste messages vide
- État initial avec message de bienvenue
- Affichage si conversation sans messages
- Optionnal: message système de conversation

## Phase 7: Conversations (60 min)

### 39. [ ] Dialog création conversation privée
- Composant `CreatePrivateConversationDialog`
- Liste utilisateurs (sans amis acceptés)
- Bouton créer conversation
- Validation: sélection utilisateur unique
- Redirection vers conversation créée

### 40. [ ] Dialog création conversation groupe
- Composant `CreateGroupConversationDialog`
- Input nom groupe
- Liste utilisateurs avec checkboxes
- Button créer
- Validation: nom requis, au moins 1 membre
- Rôle admin pour créateur

### 41. [ ] Composant ConversationCard
- Affichage conversation
- Last message preview
- Badge non-lu
- Click pour sélectionner
- Actions: delete (si admin)

### 42. [ ] Liste conversations privées/groupes
- Composant `ConversationList`
- Groupement par type (Privées, Groupes)
- Affichage trié par last_message_at
- Search filter

## Phase 8: Amis (60 min)

### 43. [ ] Recherche utilisateurs
- Composant `UserSearch`
- Input recherche
- Résultats avec username + avatar
- Button ajouter ami
- Pagination résultats

### 44. [ ] Composant FriendRequest
- Display demande d'ami
- Actions: accepter, refuser
- Indicateur badge non-lu

### 45. [ ] Liste d'amis
- Composant `FriendsList`
- Affichage liste amis
- Badge online/offline
- Status realtime
- Actions: Message, voir profil, supprimer

### 46. [ ] Liste demandes en attente
- Composant `PendingFriendRequests`
- Affichage demandes
- Accepter/refuser
- Badge notification

### 47. [ ] Store friends mis à jour
- Update friendsStore avec real-time
- Écouter INSERT/UPDATE/DELETE sur friendships
- Gestion offline states

## Phase 9: Fonctionnalités avancées (60 min)

### 48. [ ] Recherche messages
- Composant `MessageSearch`
- Input search global
- Filtrage par conversation
- Highlight résultats
- Pagination résultats

### 49. [ ] Gestion groupes (admin)
- Dialog modifier groupe
- Ajouter membres
- Retirer membres
- Changer nom/avatar
- Vérifier rôle admin

### 50. [ ] Avatar upload
- Composant `AvatarUpload`
- Preview image
- Upload vers Supabase Storage
- URL avatar
- Validation: max 2MB, jpeg/png

### 51. [ ] Statut utilisateur
- User status: online/away/offline
- Presence realtime
- Mis à jour via heartbeat (10 sec)
- Indicateur dans conversation list

## Phase 10: Finalisation (60 min)

### 52. [ ] Optimisation performances
- Lazy loading composants
- Code splitting
- Optimistic UI updates
- Debounce recherche

### 53. [ ] Tests et bugfix
- Tester login/signup flux
- Tester envoi/reception messages
- Tester création conversations
- Tester système amis
- Tester dark/light mode
- Tester responsive mobile
- Corriger bugs identifiés

### 54. [ ] Build production
- `npm run build`
- Corriger TypeScript errors
- Corriger linter errors
- Correr warnings

### 55. [ ] Tests sur build production
- Démarrer serveur dev avec build
- Tester toutes fonctionnalités
- Vérifier performance
- Corriger bugs production

### 56. [ ] Préparation déploiement Vercel
- Créer repo Git
- Commit toutes modifications
- Configurer Vercel project
- Variables d'environnement Vercel
- Deploy production
- Test production endpoint

### 57. [ ] Documentation finale
- README avec setup instructions
- Configuration Vercel
- Variables d'environnement
- Structure projet
- Points d'entrée importants

### 58. [ ] Nettoyage
- Supprimer logs temporaires
- Vérifier .gitignore
- Commit final
- README mise à jour
