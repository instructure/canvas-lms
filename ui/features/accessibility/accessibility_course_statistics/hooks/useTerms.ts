/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useMemo} from 'react'
import {useQuery} from '@tanstack/react-query'
import {groupBy} from 'es-toolkit/compat'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'

export interface Term {
  id: string
  name: string
  start_at: string | null
  end_at: string | null
}

interface EnrollmentTermsResponse {
  enrollment_terms: Array<{
    id: string
    name: string
    start_at: string | null
    end_at: string | null
    used_in_subaccount: boolean
  }>
}

export type TermGroup = 'active' | 'future' | 'past'

const EMPTY_TERMS: Term[] = []

function termGroup(term: Term): TermGroup {
  if (term.start_at && new Date(term.start_at) > new Date()) return 'future'
  if (term.end_at && new Date(term.end_at) < new Date()) return 'past'
  return 'active'
}

export const useTerms = (accountId: string) => {
  const {data, isLoading} = useQuery({
    queryKey: ['accessibility-terms', accountId],
    queryFn: async () => {
      const allTerms: Term[] = []
      let nextUrl: string | null = null

      do {
        const response: DoFetchApiResults<EnrollmentTermsResponse> =
          await doFetchApi<EnrollmentTermsResponse>(
            nextUrl
              ? {path: nextUrl}
              : {
                  path: `/api/v1/accounts/${accountId}/terms`,
                  params: {per_page: 100, subaccount_id: accountId},
                },
          )
        const page = (response.json?.enrollment_terms ?? []).filter(t => t.used_in_subaccount)
        allTerms.push(
          ...page.map(t => ({
            id: String(t.id),
            name: t.name,
            start_at: t.start_at,
            end_at: t.end_at,
          })),
        )
        nextUrl = response.link?.next?.url ?? null
      } while (nextUrl)

      return allTerms
    },
    enabled: !!accountId,
  })

  const grouped = useMemo(() => groupBy(data ?? [], termGroup), [data])

  return {
    activeTerms: grouped.active ?? EMPTY_TERMS,
    futureTerms: grouped.future ?? EMPTY_TERMS,
    pastTerms: grouped.past ?? EMPTY_TERMS,
    isLoading,
  }
}
