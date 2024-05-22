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
import gql from 'graphql-tag'

const HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS = gql`
  mutation ($assignmentId: ID!, $sectionIds: [ID!]!) {
    hideAssignmentGradesForSections(input: {assignmentId: $assignmentId, sectionIds: $sectionIds}) {
      progress {
        _id
        state
      }
    }
  }
`

const ZHideAssignmentGradesForSectionsParams = z.object({
  assignmentId: z.string(),
  sectionIds: z.array(z.string()),
})

type HideAssignmentGradesForSectionsParams = z.infer<typeof ZHideAssignmentGradesForSectionsParams>

export async function hideAssignmentGradesForSections({
  assignmentId,
  sectionIds,
}: HideAssignmentGradesForSectionsParams): Promise<any> {
  const result = await executeQuery<any>(HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS, {
    assignmentId,
    sectionIds,
  })

  return result
}
