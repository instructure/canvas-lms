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

import {AccountWithCounts, SubaccountQueryKey} from './types'
import doFetchApi from '@canvas/do-fetch-api-effect'

const SUBACCOUNTS_PER_PAGE = 100

export const generateQueryKey = (accountId: string, depth: number): SubaccountQueryKey => {
  return ['subAccountList', accountId, depth.toString()]
}

export const calculateIndent = (indent: number) => {
  return indent * 3
}

export const fetchRootAccount = async (id: string): Promise<AccountWithCounts> => {
  const params = {
    includes: ['course_count', 'sub_account_count'],
  }
  const {json} = await doFetchApi<AccountWithCounts>({
    path: `/api/v1/accounts/${id}`,
    method: 'GET',
    params,
  })
  return json!
}

export type FetchSubAccountsResponse = {
  json: AccountWithCounts[]
  nextPage: unknown
}

// we'd ultimately prefer to use a Tanstack query persister for this
// but infinite queries don't support persisters
const getSubAccountsFromSession = (accountId: string): FetchSubAccountsResponse | null => {
  const sessionData = sessionStorage.getItem(`subAccounts-${accountId}`)
  if (sessionData) {
    try {
      const parsedData = JSON.parse(sessionData) as FetchSubAccountsResponse
      return parsedData
    } catch (_error) {
      // don't care; just fetch from API
      return null
    }
  }
  return null
}

const addSubAccountsToSession = (accountId: string, response: FetchSubAccountsResponse): void => {
  const sessionData = JSON.stringify(response)
  sessionStorage.setItem(`subAccounts-${accountId}`, sessionData)
}

const fetchSubAccounts = async (
  accountId: string,
  page: string,
): Promise<FetchSubAccountsResponse> => {
  const params = {
    per_page: SUBACCOUNTS_PER_PAGE,
    page,
    include: ['course_count', 'sub_account_count'],
    order: 'name',
  }
  const {json, link} = await doFetchApi<AccountWithCounts[]>({
    path: `/api/v1/accounts/${accountId}/sub_accounts`,
    method: 'GET',
    params,
  })
  const nextPage = link?.next ? link.next.page : null
  const response: FetchSubAccountsResponse = {
    json: json!,
    nextPage,
  }
  return response
}

// retrieves first page of subaccounts from session storage if available
// otherwise fetches from API
export const getSubAccounts = async ({
  queryKey,
  pageParam,
}: {
  queryKey: SubaccountQueryKey
  pageParam: unknown
}): Promise<FetchSubAccountsResponse> => {
  const accountId = queryKey[1]
  const depth = parseInt(queryKey[2], 10)
  let response = null
  // only use session storage for first page of the first batch of subaccounts
  if (depth > 1 || (pageParam && pageParam !== '1')) {
    const pageParamStr = typeof pageParam === 'string' ? pageParam : String(pageParam)
    response = await fetchSubAccounts(accountId, pageParamStr)
  } else {
    response = getSubAccountsFromSession(accountId)
    if (response === null) response = await fetchSubAccounts(accountId, '1')
    addSubAccountsToSession(accountId, response)
  }
  return response
}
