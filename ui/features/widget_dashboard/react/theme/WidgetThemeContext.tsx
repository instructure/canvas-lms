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

import React, {createContext, useContext, useMemo} from 'react'
import {getWidgetColors} from './darkThemeColors'
import type {WidgetColors} from './darkThemeColors'

interface WidgetThemeContextValue {
  isDark: boolean
  colors: WidgetColors
  setIsDark: (isDark: boolean) => void
}

const WidgetThemeContext = createContext<WidgetThemeContextValue>({
  isDark: false,
  colors: getWidgetColors(false),
  setIsDark: () => {},
})

interface WidgetThemeProviderProps {
  isDark: boolean
  setIsDark: (isDark: boolean) => void
  children: React.ReactNode
}

export const WidgetThemeProvider = ({isDark, setIsDark, children}: WidgetThemeProviderProps) => {
  const value = useMemo(
    () => ({isDark, colors: getWidgetColors(isDark), setIsDark}),
    [isDark, setIsDark],
  )

  return <WidgetThemeContext.Provider value={value}>{children}</WidgetThemeContext.Provider>
}

export const useWidgetTheme = () => useContext(WidgetThemeContext)
