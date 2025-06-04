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

export const generateQueryKey = (accountId: string, isRoot = false): SubaccountQueryKey => {
  return isRoot ? ['account', accountId] : ['subAccountList', accountId]
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

export const fetchSubAccounts = async ({
  queryKey,
  pageParam,
}: {
  queryKey: SubaccountQueryKey
  pageParam: unknown
}): Promise<FetchSubAccountsResponse> => {
  const accountId = queryKey[1]
  const params = {
    per_page: SUBACCOUNTS_PER_PAGE,
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
