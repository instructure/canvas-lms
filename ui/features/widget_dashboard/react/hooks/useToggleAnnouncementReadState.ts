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

import {useMutation, useQueryClient} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import {ANNOUNCEMENTS_PAGINATED_KEY} from '../constants'

interface UpdateDiscussionReadStateVariables {
  discussionTopicId: string
  read: boolean
}

interface UpdateDiscussionReadStateResponse {
  updateDiscussionReadState: {
    discussionTopic: {
      _id: string
    }
  }
  errors?: Array<{message: string}>
}

const UPDATE_DISCUSSION_READ_STATE_MUTATION = gql`
  mutation UpdateAnnouncementReadState($discussionTopicId: ID!, $read: Boolean!) {
    updateDiscussionReadState(input: {
      discussionTopicId: $discussionTopicId
      read: $read
    }) {
      discussionTopic {
        _id
      }
    }
  }
`

export function useToggleAnnouncementReadState() {
  const queryClient = useQueryClient()
  const currentUserId = window.ENV?.current_user_id

  return useMutation({
    mutationFn: async (variables: UpdateDiscussionReadStateVariables) => {
      const result = await executeQuery<UpdateDiscussionReadStateResponse>(
        UPDATE_DISCUSSION_READ_STATE_MUTATION,
        variables,
      )

      if (result.errors) {
        throw new Error(
          `Failed to update read state: ${result.errors.map((err: {message: string}) => err.message).join(', ')}`,
        )
      }

      return result
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        predicate: query => {
          const queryKey = query.queryKey as unknown[]
          return queryKey[0] === ANNOUNCEMENTS_PAGINATED_KEY && queryKey[1] === currentUserId
        },
      })
    },
  })
}
