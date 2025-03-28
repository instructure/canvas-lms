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
import {useQuery} from '@tanstack/react-query'
import {useQuery as useApolloQuery} from '@apollo/client'
import {EntryCountResponse, GET_ENTRY_COUNT} from '../../graphql/Queries'

type InsightResponse = {
  workflow_state: string | null
  needs_processing?: boolean
}

type InsightEntry = {
  id: number
  entry_content: string
  entry_url: string
  entry_updated_at: string
  student_id: number
  student_name: string

  relevance_ai_classification: 'irrelevant' | 'relevant' | 'needs_review'
  relevance_ai_evaluation_notes: string

  relevance_human_reviewer: number | null
  relevance_human_feedback_liked: boolean
  relevance_human_feedback_disliked: boolean
  relevance_human_feedback_notes: string
}

const fetchInsight = async (
  context: string,
  contextId: string,
  discussionId: string,
): Promise<InsightResponse> => {
  const response = await fetch(
    `/api/v1/${context}/${contextId}/discussion_topics/${discussionId}/insights`,
  )
  if (!response.ok) {
    throw new Error('Network response was not ok')
  }

  return await response.json()
}

const fetchInsightEntries = async (
  context: string,
  contextId: string,
  discussionId: string,
): Promise<InsightEntry[]> => {
  const response = await fetch(
    `/api/v1/${context}/${contextId}/discussion_topics/${discussionId}/insights/entries`,
  )
  if (!response.ok) {
    throw new Error('Network response was not ok')
  }
  const data = await response.json()
  return data
}

export const useInsight = (context: string, contextId: string, discussionId: string) => {
  const {
    data: insightData,
    isLoading: insightIsLoading,
    error: insightError,
    refetch,
  } = useQuery({
    queryKey: ['insight', context, contextId, discussionId],
    queryFn: () => fetchInsight(context, contextId, discussionId),
  })

  const {
    data: entries,
    isLoading: entriesIsLoading,
    error: entriesError,
    isFetching,
  } = useQuery({
    queryKey: ['insightEntries', context, contextId, discussionId],
    queryFn: () => fetchInsightEntries(context, contextId, discussionId),
    enabled: insightData?.workflow_state === 'completed',
  })

  const {data: entryCount, loading: countIsLoading} = useApolloQuery<EntryCountResponse>(
    GET_ENTRY_COUNT,
    {
      variables: {
        discussionTopicId: discussionId,
      },
    },
  )

  return {
    loading: insightIsLoading || countIsLoading || (entriesIsLoading && isFetching),
    insight: insightData,
    entries,
    insightError,
    entriesError,
    entryCount: entryCount?.legacyNode?.entryCounts?.repliesCount || 0,
    refetchInsight: refetch,
  }
}
