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

import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {GetAssignmentScheduledPostQuery} from '@canvas/graphql/codegen/graphql'

const GET_ASSIGNMENT_SCHEDULED_POST = gql`
  query GetAssignmentScheduledPost($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      id: _id
      scheduledPost {
        postCommentsAt
        postGradesAt
      }
    }
  }
`

type QueryFunctionProps = {
  queryKey: string[]
}
type ScheduledPost = NonNullable<GetAssignmentScheduledPostQuery['assignment']>['scheduledPost']
export const getAssignmentScheduledPost = async ({
  queryKey,
}: QueryFunctionProps): Promise<ScheduledPost | undefined | null> => {
  const assignmentId = queryKey[1]

  if (!assignmentId) {
    return
  }

  const result = await executeQuery<GetAssignmentScheduledPostQuery>(
    GET_ASSIGNMENT_SCHEDULED_POST,
    {
      assignmentId,
    },
  )

  return result.assignment?.scheduledPost
}
