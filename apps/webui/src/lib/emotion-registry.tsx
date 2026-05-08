'use client'

import createCache from '@emotion/cache'
import { useServerInsertedHTML } from 'next/navigation'
import { CacheProvider } from '@emotion/react'
import { useState } from 'react'

export default function EmotionRegistry({ children }: { children: React.ReactNode }) {
  const [{ cache, flush }] = useState(() => {
    const emotionCache = createCache({ key: 'mui' })
    emotionCache.compat = true
    const prevInsert = emotionCache.insert
    let inserted: string[] = []
    emotionCache.insert = (...args) => {
      const serialized = args[1]
      if (emotionCache.inserted[serialized.name] === undefined) {
        inserted.push(serialized.name)
      }
      return prevInsert(...args)
    }
    const flushInserted = () => {
      const prevInserted = inserted
      inserted = []
      return prevInserted
    }
    return { cache: emotionCache, flush: flushInserted }
  })

  useServerInsertedHTML(() => {
    const names = flush()
    if (names.length === 0) return null
    let styles = ''
    for (const name of names) {
      styles += cache.inserted[name]
    }
    return (
      <style
        key={cache.key}
        data-emotion={`${cache.key} ${names.join(' ')}`}
        dangerouslySetInnerHTML={{ __html: styles }}
      />
    )
  })

  return <CacheProvider value={cache}>{children}</CacheProvider>
}
