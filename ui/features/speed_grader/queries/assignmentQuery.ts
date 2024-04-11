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
import {omit} from 'lodash'

const ASSIGNMENT_QUERY = gql`
  query AssignmentQuery($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      dueAt
      gradingType
      id
      _id
      name
      pointsPossible
      rubric {
        _id
        freeFormCriterionComments
        pointsPossible
        criteria {
          criterionUseRange
          description
          longDescription
          ignoreForScoring
          points
          ratings {
            tag: _id
            description
            longDescription
            points
          }
        }
      }
      rubricAssociation {
        hideOutcomeResults
        hidePoints
        hideScoreTotal
        useForGrading
      }
    }
  }
`

function formattedRubric(assignment: any) {
  if (!assignment.rubric || !assignment.rubricAssociation) {
    return null
  }

  const {_id, criteria, freeFormCriterionComments, pointsPossible} = assignment.rubric
  const {hideOutcomeResults, hidePoints, hideScoreTotal, useForGrading} =
    assignment.rubricAssociation
  return {
    _id,
    criteria,
    freeFormCriterionComments,
    hideOutcomeResults,
    hidePoints,
    hideScoreTotal,
    pointsPossible,
    useForGrading,
  }
}

function transformRubric(assignment: any) {
  return {
    ...omit(assignment, ['rubric', 'rubricAssociation']),
    rubric: formattedRubric(assignment),
  }
}

function transform(result: any) {
  if (!result?.assignment) {
    return null
  }

  return transformRubric(result.assignment)
}

export const ZGetAssignmentParams = z.object({
  assignmentId: z.string(),
})

type GetAssignmentParams = z.infer<typeof ZGetAssignmentParams>

export async function getAssignment<T extends GetAssignmentParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetAssignmentParams.parse(queryKey[1])
  const {assignmentId} = queryKey[1]

  const result = await executeQuery<any>(ASSIGNMENT_QUERY, {
    assignmentId,
  })

  return transform(result)
}
