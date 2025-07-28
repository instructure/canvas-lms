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

import React, {useEffect, useState} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import type {ThemeOrOverride} from '@instructure/emotion/types/EmotionTypes'
import {loadCareerTheme} from '@canvas/instui-bindings/react/career-theme-loader'

type DynamicThemeProviderProps = {
  theme: ThemeOrOverride
  children: React.ReactNode
}

export const DynamicInstUISettingsProvider = ({
  theme: initialTheme,
  children,
}: DynamicThemeProviderProps) => {
  const [theme, setTheme] = useState<ThemeOrOverride>(initialTheme)
  const urlParams = new URLSearchParams(window.location.search)
  const themeParam = urlParams.get('instui_theme')
  const isCareerTheme = themeParam === 'career'

  useEffect(() => {
    if (isCareerTheme) {
      loadCareerTheme().then(careerTheme => {
        if (careerTheme) {
          setTheme(careerTheme)
        }
      })
    }
  }, [isCareerTheme])

  return <InstUISettingsProvider theme={theme}>{children}</InstUISettingsProvider>
}
