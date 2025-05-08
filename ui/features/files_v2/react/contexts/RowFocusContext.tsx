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

export const SELECT_ALL_FOCUS_STRING = 'select_all_focus' as const
export type SELECT_ALL_FOCUS_STRING = typeof SELECT_ALL_FOCUS_STRING

type RowFocusContextType = {
  setRowToFocus: (row: number | SELECT_ALL_FOCUS_STRING | null) => void
  handleActionButtonRef: (ref: HTMLElement | null, i: number) => void
}

export const RowFocusContext = createContext<RowFocusContextType | undefined>(undefined)

export const useRowFocus = () => {
  const context = useContext(RowFocusContext)
  if (!context) {
    throw new Error('useRowFocus must be used within a RowFocusProvider')
  }
  return context
}

export function RowFocusProvider({
  children,
  value,
}: {
  children: React.ReactNode
  value: RowFocusContextType
}) {
  return <RowFocusContext.Provider value={value}>{children}</RowFocusContext.Provider>
}
