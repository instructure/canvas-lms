/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useMemo} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import {getTransitionOverride} from '@canvas/instui-bindings'
import {getK5ThemeVars, getK5ThemeOverrides} from './k5-theme'

type K5ThemeProviderProps = {
  children: React.ReactNode
  // Optional overrides — default to ENV values. Useful for testing without mocking globals.
  highContrast?: boolean
  brandVariables?: Record<string, unknown>
}

/**
 * Wraps children in an InstUISettingsProvider with K-5 theme overrides.
 * Replaces the old registerK5Theme() which called baseTheme.use() (removed in InstUI v11).
 */
export const K5ThemeProvider = ({
  children,
  highContrast = Boolean(ENV.use_high_contrast),
  brandVariables = window.CANVAS_ACTIVE_BRAND_VARIABLES ?? {},
}: K5ThemeProviderProps) => {
  const useClassicFont = Boolean(ENV.USE_CLASSIC_FONT)
  const useDyslexicFont = Boolean(ENV.use_dyslexic_font)

  const theme = useMemo(() => {
    const themeVars = getK5ThemeVars(highContrast, useClassicFont, useDyslexicFont)
    // Skip brand variables in high-contrast mode, same as getTheme()
    const brandVars = highContrast ? {} : brandVariables
    return {
      ...themeVars,
      ...brandVars,
      ...getTransitionOverride(),
      // Re-apply K5 typography last so brand variables cannot clobber it
      typography: themeVars.typography,
      componentOverrides: getK5ThemeOverrides(highContrast, useClassicFont, useDyslexicFont),
    }
  }, [highContrast, useClassicFont, useDyslexicFont, brandVariables])

  return <InstUISettingsProvider theme={theme}>{children}</InstUISettingsProvider>
}
