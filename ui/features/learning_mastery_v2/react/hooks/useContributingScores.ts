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

import {useState, useCallback, useMemo} from 'react'
import {useQueries} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'

export interface ContributingScoreAlignment {
  alignment_id: string
  associated_asset_id: string
  associated_asset_name: string
  associated_asset_type: string
  html_url: string
}

export interface ContributingScore {
  user_id: string
  alignment_id: string
  score: number
}

export interface ContributingScoresResponse {
  outcome: {
    id: string
    title: string
  }
  alignments: ContributingScoreAlignment[]
  scores: ContributingScore[]
}

export interface ContributingScoresForOutcome {
  isVisible: () => boolean
  toggleVisibility: () => void
  data?: ContributingScoresResponse
  alignments?: ContributingScoreAlignment[]
  scoresForUser: (userId: string) => (number | undefined)[]
  isLoading: boolean
  error?: unknown
}

export interface ContributingScoresManager {
  forOutcome: (outcomeId: string | number) => ContributingScoresForOutcome
}

interface UseContributingScoresProps {
  courseId: string
  studentIds: string[]
  outcomeIds: (string | number)[]
  enabled?: boolean
}

const getScoresForUser = (
  data: ContributingScoresResponse | undefined,
  userId: string,
): (number | undefined)[] => {
  if (!data) return []

  return data.alignments.map(alignment => {
    const score = data.scores.find(
      s => s.user_id === userId && s.alignment_id === alignment.alignment_id,
    )
    return score?.score
  })
}

export const useContributingScores = ({
  courseId,
  studentIds,
  outcomeIds,
  enabled = true,
}: UseContributingScoresProps) => {
  const [visibleOutcomes, setVisibleOutcomes] = useState<Set<string | number>>(new Set())

  const toggleVisibility = useCallback((outcomeId: string | number) => {
    setVisibleOutcomes(previous => {
      const newSet = new Set(previous)
      if (newSet.has(outcomeId)) {
        newSet.delete(outcomeId)
      } else {
        newSet.add(outcomeId)
      }
      return newSet
    })
  }, [])

  // Create queries for all outcomes that are visible
  const queries = useQueries({
    queries: outcomeIds.map(outcomeId => ({
      queryKey: ['contributingScores', courseId, outcomeId, studentIds],
      queryFn: async (): Promise<ContributingScoresResponse> => {
        const userIdsParams = studentIds.map(id => `user_ids[]=${id}`).join('&')
        const {json} = await doFetchApi({
          path: `/api/v1/courses/${courseId}/outcomes/${outcomeId}/contributing_scores?${userIdsParams}&only_assignment_alignments=true`,
          method: 'GET',
        })
        return json as ContributingScoresResponse
      },
      enabled: enabled && visibleOutcomes.has(outcomeId) && studentIds.length > 0,
      staleTime: 5 * 60 * 1000, // 5 minutes
    })),
  })

  const isLoading = queries.some(query => query.isLoading)
  const error = queries.find(query => query.error)?.error

  const contributingScores: ContributingScoresManager = useMemo(
    () => ({
      forOutcome: (outcomeId: string | number): ContributingScoresForOutcome => {
        const outcomeIndex = outcomeIds.indexOf(outcomeId)
        const query = queries[outcomeIndex]

        return {
          isVisible: () => visibleOutcomes.has(outcomeId),
          toggleVisibility: () => toggleVisibility(outcomeId),
          data: query?.data,
          alignments: query?.data?.alignments,
          scoresForUser: (userId: string) => getScoresForUser(query?.data, userId),
          isLoading: query?.isLoading ?? false,
          error: query?.error,
        }
      },
    }),
    [outcomeIds, queries, visibleOutcomes, toggleVisibility],
  )

  return {
    isLoading,
    error: error ? String(error) : null,
    contributingScores,
  } as const
}
