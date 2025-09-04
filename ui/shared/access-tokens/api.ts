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
import type {LinkInfo} from '@canvas/parse-link-header/parseLinkHeader'
import type {UserId} from './UserId'
import {useInfiniteQuery, useMutation} from '@tanstack/react-query'
import {doFetchWithSchema} from '@canvas/do-fetch-api-effect'
import {type Token, ZToken} from './Token'
import {z} from 'zod'
import {queryClient} from '@canvas/query'

const ZTokensResponse = z.array(ZToken)

export const useManuallyGeneratedTokens = (userId: UserId) => {
  return useInfiniteQuery({
    queryKey: ['accessTokens', userId] as [string, UserId],
    staleTime: 5 * 60 * 1000, // 5 minutes
    queryFn: ({pageParam, queryKey: [_, id]}) => {
      if (pageParam) {
        return doFetchWithSchema(
          {
            path: pageParam.url,
            method: 'GET',
          },
          ZTokensResponse,
        )
      } else {
        return doFetchWithSchema(
          {
            path: `/api/v1/users/${id}/user_generated_tokens?per_page=20`,
            method: 'GET',
          },
          ZTokensResponse,
        )
      }
    },
    initialPageParam: null as LinkInfo | null,
    getNextPageParam: currentPage => {
      return currentPage.link?.next ?? null
    },
  })
}

export const useDeleteToken = (userId: UserId) => {
  return useMutation({
    mutationFn: (tokenId: Token['id']) =>
      doFetchWithSchema(
        {
          path: `/api/v1/users/${userId}/tokens/${tokenId}`,
          method: 'DELETE',
        },
        z.unknown(),
      ),
    onSuccess: () => {
      queryClient.invalidateQueries({queryKey: ['accessTokens', userId]})
    },
  })
}
