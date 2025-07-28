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

import type {QueryFunctionContext, InfiniteData} from '@tanstack/react-query'
import type {EnrollmentTerms} from '../../../../api'
import type {NextPageTerms, Term} from '../types'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {useAllPages} from '@canvas/query'
import {useMemo} from 'react'
import {courseCopyRootKey, enrollmentTermsFetchKey} from '../types'

export const getTermsNextPage = (
  lastPage: DoFetchApiResults<EnrollmentTerms>,
): NextPageTerms | undefined => {
  const isResultEmpty = !lastPage.json?.enrollment_terms.length
  if (isResultEmpty) {
    return
  }
  // @ts-expect-error
  return lastPage.link?.next
}

export const termsQuery = async ({
  signal,
  queryKey,
  pageParam,
}: QueryFunctionContext<[string, string, string], unknown>): Promise<
  DoFetchApiResults<EnrollmentTerms>
> => {
  const [, , accountId] = queryKey
  const fetchOpts = {signal}

  // Handle the pageParam which might be unknown
  let page = '1'
  let perPage = '10'

  if (pageParam && typeof pageParam === 'object' && pageParam !== null) {
    const params = pageParam as Partial<NextPageTerms>
    page = params.page || '1'
    perPage = params.per_page || '10'
  }

  const path = `/api/v1/accounts/${accountId}/terms?page=${page}&per_page=${perPage}`

  return doFetchApi<EnrollmentTerms>({path, fetchOpts})
}

export const useTermsQuery = (rootAccountId: string) => {
  const {isLoading, isError, data, hasNextPage} = useAllPages<
    DoFetchApiResults<EnrollmentTerms>,
    Error,
    InfiniteData<DoFetchApiResults<EnrollmentTerms>>,
    [string, string, string]
  >({
    queryKey: [courseCopyRootKey, enrollmentTermsFetchKey, rootAccountId],
    queryFn: termsQuery,
    getNextPageParam: getTermsNextPage,
    initialPageParam: undefined,
  })

  const terms: Term[] = useMemo(
    () => data?.pages.flatMap(page => page.json?.enrollment_terms || []) ?? [],
    [data],
  ).map(term => ({id: term.id, name: term.name, startAt: term.start_at, endAt: term.end_at}))

  return {
    data: terms,
    isLoading,
    isError,
    hasNextPage,
  }
}
