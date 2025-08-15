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
  mutation UpdateDiscussionReadState($discussionTopicId: ID!, $read: Boolean!) {
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
    onMutate: async (variables: UpdateDiscussionReadStateVariables) => {
      // Cancel any outgoing refetches (so they don't overwrite our optimistic update)
      await queryClient.cancelQueries({
        queryKey: ['announcements', currentUserId],
      })

      // Snapshot the previous value
      const previousData = queryClient.getQueryData(['announcements', currentUserId])

      // Optimistically update the cache
      queryClient.setQueryData(['announcements', currentUserId], (old: any) => {
        if (!old) return old

        return old.map((announcement: any) => {
          if (announcement.id === variables.discussionTopicId) {
            return {
              ...announcement,
              isRead: variables.read,
              participant: variables.read ? {...announcement.participant, read: true} : null,
            }
          }
          return announcement
        })
      })

      // Return a context object with the snapshotted value
      return {previousData}
    },
    onError: (_err, _variables, context) => {
      // If the mutation fails, use the context returned from onMutate to roll back
      if (context?.previousData) {
        queryClient.setQueryData(['announcements', currentUserId], context.previousData)
      }
    },
    onSettled: () => {
      // Always refetch after error or success to ensure consistency
      queryClient.invalidateQueries({
        queryKey: ['announcements', currentUserId],
      })
    },
  })
}
