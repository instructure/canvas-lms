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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useQuery, type QueryFunctionContext} from '@tanstack/react-query'

const I18n = createI18nScope('context_modules_v2')

interface AssignmentGroup {
  _id: string
  id: string
  name: string
  state: string
}

interface AssignmentGroupsResponse {
  assignmentGroups: AssignmentGroup[]
  pageInfo: {
    hasNextPage: boolean
    endCursor: string | null
  }
}

interface GraphQLResult {
  course?: {
    assignmentGroupsConnection?: {
      edges: Array<{
        cursor: string
        node: AssignmentGroup
      }>
    }
    pageInfo: {
      hasNextPage: boolean
      endCursor: string | null
    }
  }
  errors?: Array<{
    message: string
    [key: string]: any
  }>
}

const ASSIGNMENT_GROUPS_QUERY = gql`
  query GetAssignmentGroupsQuery($courseId: ID!) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        assignmentGroupsConnection(first: 100) {
          edges {
            cursor
            node {
              _id
              id
              name
              state
            }
          }
        }
      }
    }
  }
`

async function getAssignmentGroups({
  queryKey,
  pageParam,
}: {
  queryKey: QueryFunctionContext['queryKey']
  pageParam?: unknown
}): Promise<AssignmentGroupsResponse> {
  const [_key, courseId] = queryKey
  const cursor = pageParam || null
  try {
    const result = await executeQuery<GraphQLResult>(ASSIGNMENT_GROUPS_QUERY, {
      courseId,
      cursor,
    })

    if (result.errors) {
      throw new Error(result.errors.map((err: {message: string}) => err.message).join(', '))
    }

    const edges = result.course?.assignmentGroupsConnection?.edges || []
    const pageInfo = result.course?.pageInfo || {
      hasNextPage: false,
      endCursor: null,
    }

    const assignmentGroups = edges.map(edge => {
      const node = edge.node
      return {
        ...node,
      }
    })

    return {
      assignmentGroups,
      pageInfo,
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load assignment groups: %{error}', {error: errorMessage}))
    throw error
  }
}

export const useAssignmentGroups = (courseId: string) => {
  return useQuery<AssignmentGroupsResponse, Error>({
    queryKey: ['assignmentGroups', courseId],
    queryFn: getAssignmentGroups,
  })
}
