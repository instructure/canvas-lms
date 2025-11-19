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

import {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useDebounce} from 'use-debounce'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('react_developer_keys')

export interface ApiRegistration {
  unified_tool_id: string
  global_product_id: string
  tool_name: string
  tool_id: number
  company_id: number
  company_name: string
  source: string
}

export interface UtidLookupResponse {
  api_registrations: ApiRegistration[]
}

type LookupKey = ['utid_matching', string, string[]]

interface UseUtidMatchingResult {
  matches: ApiRegistration[]
  loading: boolean
  error: string | null
}

const DEBOUNCE_DELAY = 500 // ms

/**
 * Custom hook that fetches matching UTIDs from Learn Platform API
 * based on provided redirect URIs. Automatically debounces API calls.
 *
 * @param redirectUris - Newline-separated string of redirect URIs
 * @param accountId - Account ID for the API request
 * @returns Object containing matches, loading state, and error
 */
export function useUtidMatching(
  redirectUris: string | undefined,
  accountId: string,
): UseUtidMatchingResult {
  const uris =
    redirectUris
      ?.split('\n')
      .map(uri => uri.trim())
      .filter(uri => uri.length > 0) ?? []

  const [debouncedUris] = useDebounce(uris, DEBOUNCE_DELAY)

  const {data, isLoading, error} = useQuery<ApiRegistration[], Error, ApiRegistration[], LookupKey>(
    {
      queryKey: ['utid_matching', accountId, debouncedUris],
      queryFn: async ({queryKey}) => {
        const [, id, uris] = queryKey
        const response = await doFetchApi<UtidLookupResponse>({
          path: `/api/v1/accounts/${id}/developer_keys/lookup_utids`,
          method: 'GET',
          params: {redirect_uris: uris, sources: ['partner_provided']},
        })
        return response.json?.api_registrations ?? []
      },
      enabled: debouncedUris.length > 0,
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 1,
    },
  )

  return {
    matches: data ?? [],
    loading: isLoading,
    error: error ? I18n.t('Failed to fetch matching products') : null,
  }
}
