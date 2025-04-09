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

import {QueryFunctionContext} from '@tanstack/react-query'
import {createContext, type MutableRefObject, useContext, useRef} from 'react'
import {AccountWithCounts} from './types'
import doFetchApi from '@canvas/do-fetch-api-effect'

export const calculateIndent = (indent: number) => {
  return indent * 3
}

export type FetchSubAccountsResponse = {
  json: AccountWithCounts[]
  nextPage: unknown
}

export const fetchSubAccounts = async ({
  queryKey,
  pageParam,
}: {
  queryKey: [string, string]
  pageParam: unknown
}): Promise<FetchSubAccountsResponse> => {
  const accountId = queryKey[1]
  const params = {
    per_page: '100',
    page: (pageParam || '1').toString(),
    include: ['course_count', 'sub_account_count'],
    order: 'name',
  }
  const {json, link} = await doFetchApi<AccountWithCounts[]>({
    path: `/api/v1/accounts/${accountId}/sub_accounts`,
    method: 'GET',
    params,
  })
  const nextPage = link?.next ? link.next.page : null
  return {json: json!, nextPage}
}

interface FocusContextType {
  focusId: MutableRefObject<string>
}

const Context = createContext<FocusContextType>({
  focusId: {current: ''},
})

export function FocusProvider({children}: {children: React.ReactNode}) {
  const focusId = useRef('')

  return <Context.Provider value={{focusId}}>{children}</Context.Provider>
}

export const useFocusContext = () => useContext(Context)
