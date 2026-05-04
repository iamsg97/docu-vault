import type { Metadata } from 'next'
import AppProviders from '@/providers'
import './globals.css'

export const metadata: Metadata = {
  title: {
    template: '%s | DocuVault',
    default: 'DocuVault',
  },
  description: 'AI-powered document management & verification platform',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  )
}
