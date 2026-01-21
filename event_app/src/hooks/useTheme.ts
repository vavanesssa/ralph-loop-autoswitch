import { useEffect, useState } from 'react'
import { useTheme as useNextTheme } from 'next-themes'
import { Moon, Sun } from 'lucide-react'

export function useTheme() {
  const { theme, setTheme, systemTheme } = useNextTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  const toggleTheme = () => {
    setTheme(theme === 'dark' ? 'light' : 'dark')
  }

  return {
    theme: mounted ? (theme === 'system' ? systemTheme : theme) : 'light',
    mounted,
    toggleTheme,
  }
}

export function ThemeToggle() {
  const { theme, mounted, toggleTheme } = useTheme()

  if (!mounted) {
    return (
      <div className="h-6 w-6 animate-pulse bg-gray-200 rounded-full" />
    )
  }

  return (
    <button
      onClick={toggleTheme}
      className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
      aria-label="Toggle theme"
    >
      {theme === 'dark' ? (
        <Sun className="h-5 w-5 text-yellow-500" />
      ) : (
        <Moon className="h-5 w-5 text-gray-700" />
      )}
    </button>
  )
}
