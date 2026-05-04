import { test, expect } from '@playwright/test'

test('homepage redirects to /documents', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveURL('/documents')
})
