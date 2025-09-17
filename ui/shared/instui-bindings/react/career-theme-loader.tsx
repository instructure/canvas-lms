/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import type {ThemeOrOverride} from '@instructure/emotion/types/EmotionTypes'

export async function loadCareerTheme(
  preferDark: boolean = false,
): Promise<ThemeOrOverride | null> {
  const themeUrl = preferDark ? window.ENV.CAREER_DARK_THEME_URL : window.ENV.CAREER_THEME_URL
  const fallbackUrl = preferDark ? window.ENV.CAREER_THEME_URL : null

  if (themeUrl) {
    try {
      const response = await fetch(themeUrl)
      if (!response.ok) {
        console.warn('Failed to load career theme:', response.statusText)
        // If dark theme fails and we have a fallback, try the fallback
        if (preferDark && fallbackUrl) {
          return await loadCareerTheme(false)
        }
        return null
      }
      return await response.json()
    } catch (e) {
      console.warn('Failed to load career theme:', e)
      // If dark theme fails and we have a fallback, try the fallback
      if (preferDark && fallbackUrl) {
        return await loadCareerTheme(false)
      }
      return null
    }
  }
  return null
}
