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
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {useAllPages} from '@canvas/query'
import {useMemo} from 'react'
import {courseCopyRootKey, enrollmentTermsFetchKey} from '../types'

export const getTermsNextPage = (
  lastPage: DoFetchApiResults<EnrollmentTerms>
): {page?: string; per_page?: string} | undefined => {
  return lastPage.link?.next
}

export const termsQuery = async ({
  signal,
  queryKey,
  pageParam,
}: QueryFunctionContext): Promise<DoFetchApiResults<EnrollmentTerms>> => {
  const [, , accountId] = queryKey
  const fetchOpts = {signal}
  const page = pageParam?.page || '1'
  const perPage = pageParam?.per_page || '10'
  const path: string = `/api/v1/accounts/${accountId}/terms?page=${page}&per_page=${perPage}`

  return doFetchApi<EnrollmentTerms>({path, fetchOpts})
}

export const useTermsQuery = (accountId: string) => {
  const {isLoading, isError, data} = useAllPages({
    queryKey: [courseCopyRootKey, enrollmentTermsFetchKey, accountId],
    queryFn: termsQuery,
    getNextPageParam: getTermsNextPage,
    meta: {fetchAtLeastOnce: true},
  })

  const terms = useMemo(
    () => data?.pages.flatMap(page => page.json?.enrollment_terms || []) ?? [],
    [data]
  )

  return {
    data: terms,
    isLoading,
    isError,
  }
}
