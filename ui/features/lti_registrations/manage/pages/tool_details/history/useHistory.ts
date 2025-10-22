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

import type {AccountId} from '../../../model/AccountId'
import type {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {useInfiniteQuery, useQuery} from '@tanstack/react-query'
import {queryify} from '@canvas/query/queryify'
import {
  fetchLtiRegistrationOverlayHistory,
  fetchLtiRegistrationHistory,
} from '../../../api/registrations'
import {LinkInfo} from '@canvas/parse-link-header/parseLinkHeader'

/**
 * The number of history entries to display in the UI.
 * If there are more than this number, a message will be shown.
 * Note that this must be one less than the actual limit because
 * the UI doesn't support pagination yet, so can't detect if there
 * are more than this number of entries.
 */
export const HISTORY_DISPLAY_LIMIT = 99

export const useOverlayHistory = (accountId: AccountId, registrationId: LtiRegistrationId) => {
  return useQuery({
    queryKey: ['ltiRegistrationHistory', accountId, registrationId, HISTORY_DISPLAY_LIMIT + 1],
    queryFn: queryify(fetchLtiRegistrationOverlayHistory),
  })
}

/**
 * Fetches the registration history for a given registration.
 * @param accountId The account ID to use when fetching the registration history
 * @param registrationId The registration ID to use when fetching the registration history
 * @returns
 */
export const useRegistrationHistory = (accountId: AccountId, registrationId: LtiRegistrationId) => {
  return useInfiniteQuery({
    queryKey: ['ltiRegistrationHistoryNew', accountId, registrationId] as const,
    queryFn: ({pageParam, queryKey: [, accountId, ltiRegistrationId]}) => {
      if (pageParam !== null) {
        return fetchLtiRegistrationHistory({url: pageParam.url})
      } else {
        return fetchLtiRegistrationHistory({accountId, ltiRegistrationId})
      }
    },
    getNextPageParam: lastPage => {
      if ('links' in lastPage && lastPage.links !== undefined && 'next' in lastPage.links) {
        return lastPage.links.next
      } else {
        return null
      }
    },
    initialPageParam: null as LinkInfo | null,
  })
}
