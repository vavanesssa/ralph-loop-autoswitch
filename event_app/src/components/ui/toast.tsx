import * as React from 'react'

type ToastActionElement = React.ReactElement

export interface ToastProps extends React.HTMLAttributes<HTMLDivElement> {
  title?: string
  description?: string
  variant?: 'default' | 'destructive'
  action?: ToastActionElement
}

const Toast = React.forwardRef<HTMLDivElement, ToastProps>(
  ({ className, variant = 'default', ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={`
          fixed top-4 right-4 z-50 flex w-full max-w-sm overflow-hidden rounded-md border p-4 shadow-lg
          ${variant === 'destructive' ? 'border-destructive text-destructive' : 'border-border bg-background'}
          ${className}
        `}
        {...props}
      />
    )
  }
)
Toast.displayName = 'Toast'

export { Toast }
