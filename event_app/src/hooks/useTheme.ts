import { useEffect, useState } from 'react'
import { useTheme as useNextTheme } from 'next-themes'
import { useToast } from '@/components/ui/toast'

export function useTheme() {
  const { theme, setTheme, resolvedTheme } = useNextTheme()
  const { toast } = useToast()

  useEffect(() => {
    const savedTheme = localStorage.getItem('theme')
    if (!savedTheme) {
      const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
      setTheme(systemTheme)
    }
  }, [setTheme])

  const toggleTheme = () => {
    const newTheme = theme === 'dark' ? 'light' : 'dark'
    setTheme(newTheme)
    localStorage.setItem('theme', newTheme)
    toast({
      title: `Mode ${newTheme === 'dark' ? 'sombre' : 'clair'} activé`,
    })
  }

  return { theme, resolvedTheme, toggleTheme }
}
