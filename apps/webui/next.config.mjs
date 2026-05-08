/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ['@docuvault/shared-types', '@docuvault/shared-utils'],
  experimental: {
    optimizePackageImports: ['@mui/icons-material', '@mui/material'],
  },
}

export default nextConfig
