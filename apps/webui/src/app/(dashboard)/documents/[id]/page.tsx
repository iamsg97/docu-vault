import type { Metadata } from 'next'
import Typography from '@mui/material/Typography'

export const metadata: Metadata = { title: 'Document' }

export default function DocumentDetailPage({ params }: { params: { id: string } }) {
  return <Typography variant="h4">Document {params.id}</Typography>
}
