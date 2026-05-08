import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface AuthState {
  accessToken: string | null
  setAccessToken: (token: string | null) => void
  clearAuth: () => void
}

const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      setAccessToken: (accessToken) => set({ accessToken }),
      clearAuth: () => set({ accessToken: null }),
    }),
    {
      name: 'docuvault-auth',
      partialize: (state) => ({ accessToken: state.accessToken }),
    },
  ),
)

export default useAuthStore
