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
import doFetchApi from '@canvas/do-fetch-api-effect'
import useInsightStore from './useInsightStore'

interface RequestBody {
  relevance_human_feedback_action: 'like' | 'dislike' | 'reset_like'
  relevance_human_feedback_notes: string
}

interface EntryFeedback {
  action: RequestBody['relevance_human_feedback_action']
  notes?: RequestBody['relevance_human_feedback_notes']
}

const updateEntry = async (
  context: string,
  contextId: string,
  discussionId: string,
  entryId: number,
  entryFeedback: EntryFeedback,
) => {
  const body: RequestBody = {
    relevance_human_feedback_action: entryFeedback.action,
    relevance_human_feedback_notes: entryFeedback.notes || '',
  }

  const {response} = await doFetchApi<void>({
    path: `/api/v1/${context}/${contextId}/discussion_topics/${discussionId}/insights/entries/${entryId}`,
    method: 'PUT',
    body,
  })

  if (response.status !== 200) {
    throw new Error('Update entry failed')
  }
}

export const useUpdateEntry = () => {
  const queryClient = useQueryClient()

  const context = useInsightStore(state => state.context)
  const contextId = useInsightStore(state => state.contextId)
  const discussionId = useInsightStore(state => state.discussionId)

  const {isPending, isError, mutateAsync} = useMutation({
    mutationFn: ({entryId, entryFeedback}: {entryId: number; entryFeedback: EntryFeedback}) =>
      updateEntry(context, contextId, discussionId, entryId, entryFeedback),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['insightEntries', context, contextId, discussionId],
      })
    },
  })

  return {
    isError,
    loading: isPending,
    updateEntry: mutateAsync,
  }
}
