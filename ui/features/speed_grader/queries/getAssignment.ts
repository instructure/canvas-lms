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

type Result = {
  assignment: {
    allowedAttempts: number | null
    anonymizeStudents: boolean
    gradingType: string
    id: string
    _id: string
    name: string
    pointsPossible: number
    gradeAsGroup: boolean
    gradingPeriodId: string | null
    groupAssignment: boolean
    htmlUrl: string
    supportsGradeByQuestion: boolean
    gradeByQuestionEnabled: boolean
    hasMultipleDueDates: boolean
    rubricUpdateUrl: string | null
    checkpoints: {
      pointsPossible: number
      tag: string
    }[]
    groupSet?: {
      groupsConnection: {
        nodes: {
          _id: string
          name: string
        }[]
      }
    } | null
    rubric?: {
      id: string
      freeFormCriterionComments: boolean
      ratingOrder: string
      title: string
      pointsPossible: number
      criteriaCount: number
      hidePoints: boolean
      buttonDisplay: string
      workflowState: string
      hasRubricAssociations: boolean
      criteria: {
        id: string
        criterionUseRange: boolean
        description: string
        longDescription: string | null
        ignoreForScoring: boolean
        masteryPoints: number | null
        points: number
        learningOutcomeId: string | null
        ratings: {
          id: string
          description: string
          longDescription: string | null
          points: number
        }[]
        outcome?: {
          displayName: string
          title: string
        } | null
      }[]
    } | null
    rubricAssociation?: {
      hideOutcomeResults: boolean
      hideScoreTotal: boolean
      useForGrading: boolean
      savedComments: boolean
      hidePoints: boolean
    } | null
  }
}

const QUERY = gql`
  query SpeedGrader_AssignmentQuery($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      allowedAttempts
      anonymizeStudents
      gradingType
      id
      _id
      name
      pointsPossible
      gradeAsGroup
      gradingPeriodId
      groupAssignment: hasGroupCategory
      htmlUrl
      supportsGradeByQuestion
      gradeByQuestionEnabled
      hasMultipleDueDates
      rubricUpdateUrl
      checkpoints {
        pointsPossible
        tag
      }
      groupSet {
        groupsConnection {
          nodes {
            _id
            name
          }
        }
      }
      rubric {
        id: _id
        freeFormCriterionComments
        ratingOrder
        title
        pointsPossible
        criteriaCount
        hidePoints
        buttonDisplay
        ratingOrder
        workflowState
        hasRubricAssociations
        criteria {
          id: _id
          criterionUseRange
          description
          longDescription
          ignoreForScoring
          masteryPoints
          points
          learningOutcomeId
          ratings {
            id: _id
            description
            longDescription
            points
          }
          outcome {
            displayName
            title
          }
        }
      }
      rubricAssociation {
        hideOutcomeResults
        hideScoreTotal
        useForGrading
        savedComments
        hidePoints
      }
    }
  }
`

export const ZGetAssignmentParams = z.object({
  assignmentId: z.string().min(1),
})

type GetAssignmentParams = z.infer<typeof ZGetAssignmentParams>

export function getAssignment<T extends GetAssignmentParams>({queryKey}: {queryKey: [string, T]}) {
  ZGetAssignmentParams.parse(queryKey[1])
  const {assignmentId} = queryKey[1]

  return executeQuery<Result>(QUERY, {
    assignmentId,
  })
}
