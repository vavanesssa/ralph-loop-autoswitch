import { createServerClient } from '@supabase/ssr'
import { createClient } from '@/lib/supabase/client'
import { Database } from '@/types/supabase'
import { NextRequest, NextResponse } from 'next/server'

export async function supabaseMiddleware(request: NextRequest) {
  const res = NextResponse.next()

  try {
    const supabase = createServerClient<Database>(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll()
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) => {
              request.cookies.set(name, value)
              res.headers.append('Set-Cookie', `${name}=${value}; path=/; ${options?.httpOnly ? 'httpOnly;' : ''}${options?.secure ? 'secure;' : ''}${options?.sameSite ? `sameSite=${options.sameSite};` : ''}${options?.maxAge ? `maxAge=${options.maxAge};` : ''}`)
            })
          },
        },
      }
    )

    const {
      data: { session },
    } = await supabase.auth.getSession()

    return res
  } catch (error) {
    console.error('Middleware error:', error)
    return res
  }
}

export async function getCurrentUser() {
  try {
    const supabase = await createClient()
    const {
      data: { user },
    } = await supabase.auth.getUser()

    return user
  } catch (error) {
    console.error('Error getting current user:', error)
    return null
  }
}
