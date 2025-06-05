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

import {useAllPages} from '@canvas/query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {ModulesResponse, GraphQLResult} from '../../utils/types'
import {InfiniteData} from '@tanstack/react-query'

const MODULES_STUDENT_QUERY = gql`
  query GetModulesStudentQuery($courseId: ID!, $cursor: String) {
    legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        modulesConnection(first: 100, after: $cursor) {
          edges {
            cursor
            node {
              id
              _id
              name
              position
              published
              unlockAt
              requirementCount
              requireSequentialProgress
              prerequisites {
                id
                name
                type
              }
              completionRequirements {
                id
                type
                minScore
                minPercentage
              }
              progression {
                id
                _id
                workflowState
                collapsed
                completedAt
                completed
                locked
                unlocked
                started
                currentPosition
                requirementsMet {
                  id
                  minPercentage
                  minScore
                  score
                  type
                }
                incompleteRequirements {
                  id
                  minPercentage
                  minScore
                  score
                  type
                }
              }
              submissionStatistics {
                latestDueAt
                missingAssignmentCount
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

async function getModulesStudent({
  queryKey,
  pageParam,
}: {queryKey: any; pageParam?: unknown}): Promise<ModulesResponse> {
  const [_key, courseId] = queryKey
  const cursor = pageParam ? String(pageParam) : null

  const result = await executeQuery<GraphQLResult>(MODULES_STUDENT_QUERY, {
    courseId,
    cursor,
  })

  if (result.errors) {
    throw new Error(result.errors.map((err: {message: string}) => err.message).join(', '))
  }

  const edges = result.legacyNode?.modulesConnection?.edges || []
  const pageInfo = result.legacyNode?.modulesConnection?.pageInfo || {
    hasNextPage: false,
    endCursor: null,
  }

  const modules = edges.map(edge => {
    const node = edge.node
    return {
      ...node,
    }
  })

  return {
    modules,
    pageInfo,
  }
}

export function useModulesStudent(courseId: string) {
  return useAllPages<ModulesResponse, Error, InfiniteData<ModulesResponse>, [string, string]>({
    queryKey: ['modulesStudent', courseId],
    queryFn: getModulesStudent,
    initialPageParam: undefined,
    getNextPageParam: (lastPage: ModulesResponse) =>
      lastPage.pageInfo.hasNextPage ? lastPage.pageInfo.endCursor : undefined,
    refetchOnWindowFocus: true,
    // 15 minutes, will reload on refresh because there is no persistence
    staleTime: 15 * 60 * 1000,
  })
}
