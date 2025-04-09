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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {queryClient, useQuery} from '@canvas/query'
import {createContext, useContext, useState} from 'react'
import {AccountWithCounts} from './types'
import {Account} from 'api'

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
  overMax: boolean
}

const Context = createContext<FocusContextType>({
  focusRef: null,
  focusId: '',
  setFocusId: () => {},
  setFocusRef: () => {},
  overMax: true,
})

const fetchTotalCount = async (id: string): Promise<Account[]> => {
  const params = {
    recursive: true,
    page: '1',
    per_page: '100',
  }
  const {json} = await doFetchApi<Account[]>({
    path: `/api/v1/accounts/${id}/sub_accounts`,
    params,
    method: 'GET',
  })
  return json as Account[]
}

export function FocusProvider({
  children,
  accountId,
}: {children: React.ReactNode; accountId: string}) {
  const [focusId, setFocusId] = useState('')
  const [focusRef, setFocusRef] = useState<HTMLElement | null>(null)

  const {data} = useQuery({
    queryKey: ['subaccountTotalCount', accountId],
    queryFn: () => fetchTotalCount(accountId),
  })

  // if under max:
  //   - all account trees auto-expand
  //   - fetches are done immediately for all accounts
  // if over max:
  //   - all account trees are collapsed
  //   - fetches are done on expansion
  let overMax = true
  if (data) {
    overMax = data.length >= 100
  }
  return (
    <Context.Provider value={{focusRef, setFocusRef, focusId, setFocusId, overMax}}>
      {children}
    </Context.Provider>
  )
}

export const useFocusContext = () => useContext(Context)
