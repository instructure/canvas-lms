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

import {createContext, useContext} from 'react'
import {File, Folder} from '../../interfaces/File'

type RowsContextType = {
  setCurrentRows: (rows: (File | Folder)[]) => void
  currentRows: (File | Folder)[]
}

export const RowsContext = createContext<RowsContextType | undefined>(undefined)

export const useRows = () => {
  const context = useContext(RowsContext)
  if (!context) {
    throw new Error('useRows must be used within a RowsProvider')
  }
  return context
}

export function RowsProvider({
  children,
  value,
}: {
  children: React.ReactNode
  value: RowsContextType
}) {
  return <RowsContext.Provider value={value}>{children}</RowsContext.Provider>
}
