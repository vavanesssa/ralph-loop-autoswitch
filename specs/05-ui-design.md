# Spécification UI/Design

## Stack UI

- Tailwind CSS pour les styles
- ShadCN/UI pour les composants
- Lucide React pour les icônes

## Layout

### Structure principale
```
┌─────────────────────────────────────────────┐
│ Header (logo, search, user menu)            │
├──────────┬──────────────────────────────────┤
│ Sidebar  │ Main Content                     │
│ - Convos │ - Messages                       │
│ - Friends│ - Input                          │
│          │                                  │
└──────────┴──────────────────────────────────┘
```

### Responsive
- Desktop: sidebar visible
- Mobile: sidebar en drawer
- Breakpoint: 768px

## Thème

### Dark Mode (default)
- Background: slate-900
- Cards: slate-800
- Text: slate-100
- Accent: blue-500

### Light Mode
- Background: white
- Cards: slate-50
- Text: slate-900
- Accent: blue-600

### Toggle
- Bouton dans le header
- Persistance en localStorage
- Utilisation next-themes

## Composants ShadCN requis

- Button
- Input
- Avatar
- Card
- Dialog
- DropdownMenu
- ScrollArea
- Tabs
- Badge
- Skeleton (loading states)
- Toast (notifications)
