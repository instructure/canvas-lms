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
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'

const QUERY = gql`
  query SpeedGrader_AssignmentQuery($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      allowedAttempts
      anonymizeStudents
      dueAt
      gradingType
      id
      _id
      name
      pointsPossible
      gradeAsGroup
      gradingPeriodId
      groupAssignment: hasGroupCategory
      htmlUrl
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
      }
    }
  }
`

function formattedRubric(assignment: any) {
  if (!assignment.rubric || !assignment.rubricAssociation) {
    return null
  }

  const {_id, criteria, freeFormCriterionComments, pointsPossible, title} = assignment.rubric
  criteria.forEach((criterion: any) => {
    criterion.ratings.forEach((rating: any) => {
      rating.criterionId = criterion.id
    })
  })
  const {hideOutcomeResults, hidePoints, hideScoreTotal, useForGrading, savedComments} =
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
    title,
    savedComments: JSON.parse(savedComments || null),
  }
}

function formattedGroups(assignment: any) {
  const groups = assignment.groupSet?.groupsConnection?.nodes ?? []
  return groups.map(({_id, name}: any) => ({_id, name}))
}

function transform(result: any) {
  if (!result?.assignment) {
    return null
  }

  const onSaveRubricAssessment = (assessments: RubricAssessmentData[], userId: string) => {
    const {assessment_user_id, anonymous_id, assessment_type} = ENV.RUBRIC_ASSESSMENT ?? {}

    // TODO: anonymous grading stuff here, see convertSubmittedAssessmentin RubricAssessmentContainerWrapper
    // if (assessment_user_id) {
    //   data['rubric_assessment[user_id]'] = assessment_user_id
    // } else {
    //   data['rubric_assessment[anonymous_id]'] = anonymous_id
    // }
    const rubric_assessment: {[key: string]: any} = {}
    rubric_assessment.user_id = userId
    rubric_assessment.assessment_type = assessment_type

    assessments.forEach(assessment => {
      const pre = `criterion_${assessment.criterionId}`
      rubric_assessment[pre] = {}
      rubric_assessment[pre].points = assessment.points
      rubric_assessment[pre].comments = assessment.comments
      rubric_assessment[pre].save_comment = assessment.saveCommentsForLater ? '1' : '0'
      rubric_assessment[pre].description = assessment.description
      if (assessment.id) {
        rubric_assessment[pre].rating_id = assessment.id
      }
    })
    const data: any = {rubric_assessment}
    // TODO: moderated grading support here, see saveRubricAssessment in speed_grader.tsx
    // TODO: anonymous grading support, see saveRubricAssessment in speed_grader.tsx

    data.graded_anonymously = false
    const url = ENV.update_rubric_assessment_url!
    const method = 'POST'
    return doFetchApi({
      path: url,
      method,
      body: data,
    })
  }

  return {
    ...omit(result.assignment, ['groupSet', 'rubric', 'rubricAssociation']),
    groups: formattedGroups(result.assignment),
    rubric: formattedRubric(result.assignment),
    onSaveRubricAssessment,
  }
}

export const ZGetAssignmentParams = z.object({
  assignmentId: z.string().min(1),
})

type GetAssignmentParams = z.infer<typeof ZGetAssignmentParams>

export async function getAssignment<T extends GetAssignmentParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetAssignmentParams.parse(queryKey[1])
  const {assignmentId} = queryKey[1]

  const result = await executeQuery<any>(QUERY, {
    assignmentId,
  })

  return transform(result)
}
