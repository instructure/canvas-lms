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

import React, {createContext, useContext} from 'react'

interface ResponsiveContextValue {
  isMobile: boolean
  isTablet: boolean
  isDesktop: boolean
  matches: string[]
}

const ResponsiveContext = createContext<ResponsiveContextValue>({
  isMobile: false,
  isTablet: false,
  isDesktop: true,
  matches: ['desktop'],
})

interface ResponsiveProviderProps {
  matches: string[]
  children: React.ReactNode
}

export const ResponsiveProvider: React.FC<ResponsiveProviderProps> = ({matches, children}) => {
  const isMobile = matches.includes('mobile')
  const isTablet = matches.includes('tablet')
  const isDesktop = matches.includes('desktop')

  const value = {
    isMobile,
    isTablet,
    isDesktop,
    matches,
  }

  return <ResponsiveContext.Provider value={value}>{children}</ResponsiveContext.Provider>
}

export const useResponsiveContext = (): ResponsiveContextValue => {
  const context = useContext(ResponsiveContext)
  if (!context) {
    throw new Error('useResponsiveContext must be used within a ResponsiveProvider')
  }
  return context
}
