import type { Metadata } from 'next'
import Box from '@mui/material/Box'
import Typography from '@mui/material/Typography'

export const metadata: Metadata = { title: 'Sign Up' }

export default function SignUpPage() {
  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        bgcolor: 'background.default',
      }}
    >
      <Typography variant="h4">Sign Up</Typography>
    </Box>
  )
}
