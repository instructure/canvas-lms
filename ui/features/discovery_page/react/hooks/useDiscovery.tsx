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

import {createContext, useContext, useState} from 'react'
import type {DiscoveryContextType, DiscoveryProviderProps} from '../types'

const DiscoveryContext = createContext<DiscoveryContextType | undefined>(undefined)

export function useDiscovery() {
  const ctx = useContext(DiscoveryContext)

  if (!ctx) throw new Error('useDiscovery must be used within DiscoveryProvider')

  return ctx
}

export function DiscoveryProvider({children}: DiscoveryProviderProps) {
  const [modalOpen, setModalOpen] = useState(false)

  return (
    <DiscoveryContext.Provider
      value={{
        modalOpen,
        setModalOpen,
        authProviders: ENV.auth_providers,
        previewUrl: ENV.discovery_page_url,
      }}
    >
      {children}
    </DiscoveryContext.Provider>
  )
}
