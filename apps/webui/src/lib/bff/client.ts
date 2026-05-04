import axios from 'axios'

const bffClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_BFF_URL ?? 'http://localhost:3000',
  headers: {
    'Content-Type': 'application/json',
  },
})

bffClient.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    try {
      const stored = localStorage.getItem('docuvault-auth')
      const parsed = stored ? (JSON.parse(stored) as { state?: { accessToken?: string } }) : null
      const token = parsed?.state?.accessToken
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
    } catch {
      // storage unavailable — continue without auth header
    }
  }
  return config
})

export default bffClient
