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

import type {QueryFunctionContext} from '@tanstack/react-query'
import type {EnrollmentTerms} from '../../../../api'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {Term} from '../types'

export const termsQuery = async ({signal, queryKey}: QueryFunctionContext): Promise<Term[]> => {
  const [, , accountId] = queryKey
  const data: Array<Term> = []
  const fetchOpts = {signal}
  let path: any = `/api/v1/accounts/${accountId}/terms`

  while (path) {
    // eslint-disable-next-line no-await-in-loop
    const {json, link} = await doFetchApi<EnrollmentTerms>({path, fetchOpts})
    if (json) data.push(...json.enrollment_terms)
    path = link?.next?.url || null
  }
  return data
}
