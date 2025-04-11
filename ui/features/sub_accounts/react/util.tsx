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

import {queryClient} from '@canvas/query'
import {createContext, useContext, useState} from 'react'

export const calculateIndent = (indent: number) => {
  return indent * 3
}

export const resetQuery = (id: string) => {
  const queryKey = ['subAccountList', id]
  queryClient.invalidateQueries({queryKey})
}

interface FocusContextType {
  focusRef: HTMLElement | null
  focusId: string
  setFocusRef: React.Dispatch<React.SetStateAction<HTMLElement | null>>
  setFocusId: React.Dispatch<React.SetStateAction<string>>
}

const Context = createContext<FocusContextType>({
  focusRef: null,
  focusId: '',
  setFocusId: () => {},
  setFocusRef: () => {},
})

export function FocusProvider({children}: {children: React.ReactNode}) {
  const [focusId, setFocusId] = useState('')
  const [focusRef, setFocusRef] = useState<HTMLElement | null>(null)

  return (
    <Context.Provider value={{focusRef, setFocusRef, focusId, setFocusId}}>
      {children}
    </Context.Provider>
  )
}

export const useFocusContext = () => useContext(Context)
