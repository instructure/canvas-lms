/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {z} from 'zod'
import {executeQuery} from '@canvas/query/graphql'
import resolveProgress from '@canvas/progress/resolve_progress'
import gql from 'graphql-tag'

const POST_ASSIGNMENT_GRADES = gql`
  mutation ($assignmentId: ID!, $gradedOnly: Boolean) {
    postAssignmentGrades(input: {assignmentId: $assignmentId, gradedOnly: $gradedOnly}) {
      progress {
        _id
        state
      }
    }
  }
`

export async function resolvePostAssignmentGradesStatus(payload: {
  queryKey: [string, {_id: string; workflowState: string}]
}) {
  const result = await resolveProgress({
    url: `/api/v1/progress/${payload.queryKey[1]._id}`,
    workflow_state: payload.queryKey[1].workflowState,
  }).then((data: any) => {
    return data
  })

  return result
}

const ZPostAssignmentGradesForSectionsParams = z.object({
  assignmentId: z.string(),
  gradedOnly: z.boolean(),
})

type PostAssignmentGradesForSectionsParams = z.infer<typeof ZPostAssignmentGradesForSectionsParams>

export async function postAssignmentGradesForSections({
  assignmentId,
  gradedOnly,
}: PostAssignmentGradesForSectionsParams): Promise<any> {
  const result = executeQuery<any>(POST_ASSIGNMENT_GRADES, {
    assignmentId,
    gradedOnly,
  })

  return result
}
