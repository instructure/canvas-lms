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
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import {useMutation, queryClient} from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'

export const useAddTagMembership = () => {
  return useMutation<{ok: boolean}, Error, {groupId: number | string; userIds: number[]}>({
    mutationFn: async ({groupId, userIds}) => {
      try {
        const result = await doFetchApi<{ok: boolean}>({
          path: `/api/v1/groups/${groupId}/memberships`,
          method: 'POST',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          body: {members: userIds},
        })
        if (!result.response.ok) {
          throw new Error(`Failed to add users membership: ${result.response.statusText}`)
        }
        return {ok: true}
      } catch (error) {
        console.error('Mutation failed:', error)
        throw error
      }
    },
    onSuccess: async () => {
      // We are invalidating all queries that start with 'differentiationTagCategories'
      // undefined: we aren't using any other query filters to determine what to invalidate
      // cancelRefetch: tells the query client to cancel any ongoing refetch for the matching queries
      await queryClient.invalidateQueries(['differentiationTagCategories'], undefined, {
        cancelRefetch: true,
      })
    },
    onError: error => {
      console.error('Error adding users membership:', error)
    },
  })
}
