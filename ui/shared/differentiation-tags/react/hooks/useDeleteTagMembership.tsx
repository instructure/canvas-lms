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
import { useMutation } from '@canvas/query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {UserTags} from '../types'

export const useDeleteTagMembership = () => {
  return useMutation<{ ok: boolean }, Error, { groupId: number, userId: number, refetch: () => void }>({
    mutationFn: async ({groupId, userId}) => {
      try {
        const result = await doFetchApi<{ ok: boolean }>({
          path: `/api/v1/groups/${groupId}/users/${userId}`,
          method: 'DELETE',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
        })
        if (!result.response.ok) {
          throw new Error(`Failed to delete user membership: ${result.response.statusText}`)
        }

        if (!result.json) {
          throw new Error('No data returned from the server')
        }

        return result.json
      }
      catch (error) {
        console.error('Mutation failed:', error)
        throw error
      }
    },
    onSuccess: (_, props) => {
        props.refetch()
    },
    onError: (error) => {
      console.error('Error deleting user membership:', error)
    },
  })
}