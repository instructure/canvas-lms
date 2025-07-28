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
import {Assignment} from './Assignment'
import {Submission} from './Submission'
import {executeQuery} from '@canvas/graphql'
import {QueryFunctionContext, InfiniteData} from '@tanstack/react-query'
import {useAllPages} from '@canvas/query'

export const ASSIGNMENTS = gql`
  query GetAssignments($courseID: ID!, $gradingPeriodID: ID, $studentId: ID!, $after: String) {
    legacyNode(_id: $courseID, type: Course) {
      ... on Course {
        assignmentsConnection(filter: {gradingPeriodId: $gradingPeriodID, userId: $studentId}, after: $after) {
          nodes {
            ...Assignment
            submissionsConnection(filter: {userId: $studentId, includeUnsubmitted: true}) {
              nodes {
                ...Submission
                submittedAt
              }
            }
          }
          pageInfo {
            endCursor
            hasPreviousPage
            hasNextPage
            startCursor
          }
        }
      }
    }
  }
  ${Assignment.fragment}
  ${Submission.fragment}
`

type AssignmentPage = {
  legacyNode: {
    assignmentsConnection: {
      nodes: Array<unknown>
      pageInfo: {
        endCursor: string
        hasPreviousPage: boolean
        hasNextPage: boolean
        startCursor: string
      }
    }
  }
}

export function fetchAssignments(
  context: QueryFunctionContext<readonly unknown[]>,
): Promise<AssignmentPage> {
  const courseID = context.queryKey[2]
  const gradingPeriodID = context.queryKey[3]
  const studentId = context.queryKey[4]
  const afterValue = context.pageParam

  if (typeof courseID !== 'string') {
    throw new Error('courseID must be a string')
  }

  if (
    !(
      typeof gradingPeriodID === 'string' ||
      gradingPeriodID === null ||
      gradingPeriodID === undefined
    )
  ) {
    throw new Error('gradingPeriodId must be a string, null, or undefined')
  }

  if (typeof studentId !== 'string') {
    throw new Error('studentId must be a string')
  }

  if (afterValue !== undefined && typeof afterValue !== 'string') {
    throw new Error('after must be a string or undefined')
  }

  const after = afterValue as string | undefined

  return executeQuery<AssignmentPage>(ASSIGNMENTS, {
    courseID,
    gradingPeriodID,
    studentId,
    after,
  })
}

type AssignmentsResult = {
  assignments: unknown[]
  pageInfo:
    | {
        endCursor: string
        hasPreviousPage: boolean
        hasNextPage: boolean
        startCursor: string
      }
    | undefined
}

function selectAssignments(data: InfiniteData<AssignmentPage, unknown>): AssignmentsResult {
  if (!data || !data.pages || data.pages.length === 0) {
    return {
      assignments: [],
      pageInfo: undefined,
    }
  }

  const assignments = data.pages.flatMap(
    (page: AssignmentPage) => page.legacyNode?.assignmentsConnection?.nodes || [],
  )

  const lastPage = data.pages[data.pages.length - 1]
  const pageInfo = lastPage?.legacyNode?.assignmentsConnection?.pageInfo

  return {
    assignments,
    pageInfo,
  }
}

export function useAssignments({
  courseID,
  gradingPeriodId,
  studentId,
  cursor,
}: {
  courseID: string
  gradingPeriodId?: string | null
  studentId: string
  cursor?: string | null
}) {
  return useAllPages<AssignmentPage, unknown, AssignmentsResult>({
    queryKey: ['grade_summary', 'assignments', courseID, gradingPeriodId, studentId, cursor],
    queryFn: fetchAssignments,
    initialPageParam: undefined,
    getNextPageParam: (lastPage: AssignmentPage) => {
      const pageInfo = lastPage.legacyNode?.assignmentsConnection?.pageInfo

      const nextPageParam = pageInfo?.hasNextPage ? pageInfo.endCursor : undefined

      return nextPageParam
    },
    select: selectAssignments,
  })
}
