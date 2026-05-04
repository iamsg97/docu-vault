'use client'

import { useEffect } from 'react'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'
import Button from '@mui/material/Button'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // intentional: boundary errors warrant browser-side logging
    console.error(error)
  }, [error])

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        gap: 2,
      }}
    >
      <Typography variant="h5">Something went wrong</Typography>
      <Typography variant="body2" color="text.secondary">
        {error.message}
      </Typography>
      <Button onClick={reset} variant="contained">
        Try again
      </Button>
    </Box>
  )
}
