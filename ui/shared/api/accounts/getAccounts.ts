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

import {safelyFetch} from '@canvas/do-fetch-api-effect'
import {ZAccount} from '@canvas/schemas'
import type {QueryFunctionContext} from '@tanstack/react-query'
import {z} from 'zod'

const ZAccountWithCounts = ZAccount.extend({
  course_count: z.number(),
  sub_account_count: z.number(),
}).strict()

const ZAccounts = z.array(ZAccountWithCounts)

export type Accounts = z.infer<typeof ZAccounts>

const ACCOUNTS_PATH = '/api/v1/accounts'
const ACC_PER_PAGE = 50

export default async function getAccounts({queryKey, signal}: QueryFunctionContext) {
  if (!Array.isArray(queryKey) || typeof queryKey[1] !== 'object') {
    throw new Error('Invalid query key')
  }
  const pageIndex = queryKey[1].pageIndex
  const {json, link} = await safelyFetch(
    {
      path: `${ACCOUNTS_PATH}?include=course_count,sub_account_count&per_page=${ACC_PER_PAGE}&page=${pageIndex}`,
      method: 'GET',
      signal,
    },
    ZAccounts,
  )

  return {json, link}
}
