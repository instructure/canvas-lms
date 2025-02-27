/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {createContext, type ReactNode, useContext, useEffect, useMemo, useState} from 'react'

interface HelpTrayContextType {
  isHelpTrayOpen: boolean
  openHelpTray: () => void
  closeHelpTray: () => void
}

const HelpTrayContext = createContext<HelpTrayContextType | undefined>(undefined)

interface Props {
  children: ReactNode
}

const HELP_TRAY_HASH = 'help'

export const HelpTrayProvider = ({children}: Props) => {
  const [isHelpTrayOpen, setHelpTrayOpen] = useState(false)

  const openHelpTray = () => {
    setHelpTrayOpen(true)
    if (window.location.hash !== `#${HELP_TRAY_HASH}`) {
      window.history.pushState(null, '', `#${HELP_TRAY_HASH}`)
    }
  }

  const closeHelpTray = () => {
    setHelpTrayOpen(false)
    if (window.location.hash === `#${HELP_TRAY_HASH}`) {
      window.history.replaceState(null, '', window.location.pathname + window.location.search)
    }
  }

  useEffect(() => {
    const handleHashChange = () => {
      setHelpTrayOpen(window.location.hash === `#${HELP_TRAY_HASH}`)
    }
    // initialize state based on current hash
    handleHashChange()
    // listen for future hash changes
    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  const value = useMemo(
    () => ({
      isHelpTrayOpen,
      openHelpTray,
      closeHelpTray,
    }),
    [isHelpTrayOpen],
  )

  return <HelpTrayContext.Provider value={value}>{children}</HelpTrayContext.Provider>
}

export const useHelpTray = (): HelpTrayContextType => {
  const context = useContext(HelpTrayContext)

  if (context === undefined) {
    throw new Error('useHelpTray must be used within a HelpTrayProvider')
  }

  return context
}
