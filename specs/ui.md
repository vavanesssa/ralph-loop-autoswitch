# Spécifications - UI & Theming

## Objectif
Interface utilisateur moderne, responsive et cohérente avec dark/light mode.

## Design System

### Couleurs

**Light Mode:**
- Background: `#ffffff`, `#f8fafc`
- Foreground: `#0f172a`
- Primary: `#3b82f6`
- Secondary: `#64748b`
- Success: `#22c55e`
- Warning: `#f59e0b`
- Error: `#ef4444`
- Border: `#e2e8f0`

**Dark Mode:**
- Background: `#0f172a`, `#1e293b`
- Foreground: `#f8fafc`
- Primary: `#3b82f6`
- Secondary: `#94a3b8`
- Success: `#4ade80`
- Warning: `#fbbf24**
- Error: `#f87171`
- Border: `#334155`

### Composants ShadCN à Installer

```bash
npx shadcn-ui@latest add button input card label avatar badge dialog dropdown-menu scroll-area tabs
```

**Composants requis:**
- Button - Boutons principaux, secondaires, ghost, danger
- Input - Champs de texte avec validation
- Card - Conteneurs pour sections
- Label - Labels pour inputs
- Avatar - Affichage avatars
- Badge - Badges (notification, online, etc.)
- Dialog - Modales
- DropdownMenu - Menu contextuel
- ScrollArea - Zones de scroll
- Tabs - Navigation par onglets
- TabsContent - Contenu des tabs
- TabsList - Liste des tabs
- TabsTrigger - Boutons tabs
- Skeleton - Chargement skeleton
- Toast - Notifications
- ScrollArea - Scrollbars personnalisées
- Separator - Séparateurs visuels
- AlertDialog - Confirmation dialog
- Select - Sélection dropdown
```

## Layout Structure

### Main Layout (Authenticated)

**Structure:**
```
┌──────────────────────────────────────────────────────────┐
│  [Logo] [Theme Toggle]  [User Menu]          [+ Message] │
├──────────┬───────────────────────────────────────────────┤
│ Conversa│   Conversation Active                        │
│ tions    │                                               │
│ [Liste]  │   ┌───────────────────────────────────────┐ │
│          │   │ [Avatar + Title]       [Info Actions] │ │
│ 📧 UserA │   ├───────────────────────────────────────┤ │
│          │   │   Zone des messages                    │ │
│ 📧 GroupX│   │   (ScrollArea)                        │ │
│          │   │                                       │ │
│ 👤 UserC │   │   [Input]                             │ │
│          │   └───────────────────────────────────────┘ │
└──────────┴───────────────────────────────────────────────┘
```

### Page de Login

```
┌─────────────────────────────────────────┐
│                                         │
│              [Logo]                     │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Welcome to Event App             │  │
│  │  ─────────────────────────────────  │  │
│  │                                    │  │
│  │  Email                             │  │
│  │  [_______________________________]  │  │
│  │                                    │  │
│  │  Password                         │  │
│  │  [_______________________________]  │  │
│  │                                    │  │
│  │  [Se connecter]                   │  │
│  │                                    │  │
│  │  Pas de compte? [S'inscrire]      │  │
│  │                                    │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Responsive Design

### Breakpoints
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: >= 1024px

### Mobile Behavior

**Sidebar conversations:**
- Drawer (modal) par défaut
- Hamburger menu pour ouvrir
- Overlay sombre quand ouvert
- Fermer sur clic extérieur

**Messages zone:**
- Fullscreen sur mobile
- Bouton retour (arrow left) quand conversation sélectionnée
- Sidebar toggle à droite

### Desktop Behavior
- Sidebar visible par défaut
- Messages zone visible et grand
- Side-by-side layout

## Theming

### next-themes Setup
```typescript
// providers/theme-provider.tsx
'use client';
import * as React from 'react';
import { ThemeProvider as NextThemesProvider } from 'next-themes';
import { type ThemeProviderProps } from 'next-themes/dist/types';

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
```

```typescript
// layout.tsx
import { ThemeProvider } from '@/components/theme-provider';

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

### Theme Toggle
- Position: Top right, logo à gauche
- Icones: Moon/Sun (cycling)
- Respecte system preference par défaut
- Persistance localStorage

## Animations

- Transitions smooth 150-200ms
- Fades pour modales (fade-in/out)
- Slide pour drawer
- Pulse pour online indicator
- Scale pour hover buttons

## Accessibility

- Contraste minimal 4.5:1
- Focus rings visibles
- Labels pour tous les inputs
- Alt text pour images
- Keyboard navigation supportée

## Stack Technique

- Next.js App Router
- Tailwind CSS
- shadcn/ui components
- next-themes (dark/light mode)
- Lucide React (icons)

## User Stories

**US-001**: Je veux pouvoir basculer entre dark et light mode
**US-002**: Je veux voir une interface responsive sur mobile
**US-003**: Je veux des composants UI cohérents et modernes
**US-004**: Je veux des animations fluides
**US-005**: Je veux une navigation accessible au clavier
**US-006**: Je veux voir mes avatars et couleurs cohérentes
