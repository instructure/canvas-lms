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

import {gql} from '@apollo/client'
import qs from 'qs'
import {executeQuery} from '@canvas/graphql'
import type {RubricFormProps, GenerateCriteriaFormProps} from '../types/RubricForm'
import type {CanvasProgress} from '@canvas/progress/ProgressHelpers'
import type {Rubric, RubricAssociation} from '@canvas/rubrics/react/types/rubric'
import {
  mapRubricAssociationUnderscoredKeysToCamelCase,
  mapRubricUnderscoredKeysToCamelCase,
} from '@canvas/rubrics/react/utils'
import getCookie from '@instructure/get-cookie'

const RUBRIC_QUERY = gql`
  query SharedRubricQuery($rubricId: ID!) {
    rubric(id: $rubricId) {
      id: _id
      title
      hasRubricAssociations
      rubricAssociationForContext {
        hidePoints
        hideScoreTotal
        hideOutcomeResults
        id: _id
        useForGrading
      }
      buttonDisplay
      ratingOrder
      freeFormCriterionComments
      workflowState
      pointsPossible
      unassessed
      criteria {
        id: _id
        ratings {
          description
          longDescription
          points
          id: _id
        }
        outcome {
          displayName
          title
        }
        learningOutcomeId
        ignoreForScoring
        masteryPoints
        points
        longDescription
        description
        criterionUseRange
      }
    }
  }
`

export type RubricAssociationQueryResponse = {
  hidePoints: boolean
  hideScoreTotal: boolean
  hideOutcomeResults: boolean
  id: string
  useForGrading: boolean
}
export type RubricQueryResponse = Pick<
  Rubric,
  | 'id'
  | 'title'
  | 'criteria'
  | 'hidePoints'
  | 'freeFormCriterionComments'
  | 'pointsPossible'
  | 'buttonDisplay'
  | 'ratingOrder'
  | 'workflowState'
> & {
  unassessed: boolean
  hasRubricAssociations: boolean
  rubricAssociationForContext?: RubricAssociationQueryResponse
}

type FetchRubricResponse = {
  rubric: RubricQueryResponse
}
type FetchRubricParams = {
  queryKey: string[]
}
export const fetchRubric = async ({
  queryKey,
}: FetchRubricParams): Promise<RubricQueryResponse | null> => {
  const [_, rubricId] = queryKey
  if (!rubricId) return null

  const {rubric} = await executeQuery<FetchRubricResponse>(RUBRIC_QUERY, {
    rubricId,
  })

  return rubric
}

export type SaveRubricResponse = {
  rubric: Rubric & {canUpdate?: boolean; association_count?: number}
  rubricAssociation: RubricAssociation
}
export const saveRubric = async (
  rubric: RubricFormProps,
  assignmentId?: string,
): Promise<SaveRubricResponse> => {
  const {
    id,
    title,
    hidePoints,
    freeFormCriterionComments,
    accountId,
    courseId,
    ratingOrder,
    buttonDisplay,
    workflowState,
    hideOutcomeResults,
    hideScoreTotal,
    useForGrading,
    rubricAssociationId,
  } = rubric

  const associationType = assignmentId ? 'Assignment' : accountId ? 'Account' : 'Course'

  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  let url = `${urlPrefix}/rubrics/${id ?? ''}`

  if (associationType === 'Assignment') {
    url = `${url}?rubric_association_id=${rubricAssociationId}`
  }
  const method = id ? 'PATCH' : 'POST'

  const criteria = rubric.criteria.map(criterion => {
    return {
      id: criterion.id,
      description: criterion.description,
      long_description: criterion.longDescription,
      points: criterion.points,
      outcome: {
        display_name: criterion.outcome?.displayName,
        title: criterion.outcome?.title,
      },
      learning_outcome_id: criterion.learningOutcomeId,
      ignore_for_scoring: criterion.ignoreForScoring,
      criterion_use_range: criterion.criterionUseRange,
      ratings: criterion.ratings.map(rating => ({
        description: rating.description,
        long_description: rating.longDescription,
        points: rating.points,
        id: rating.id,
      })),
    }
  })

  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: qs.stringify({
      _method: method,
      rubric: {
        title,
        hide_points: hidePoints,
        free_form_criterion_comments: freeFormCriterionComments ? 1 : 0,
        criteria,
        button_display: buttonDisplay,
        rating_order: ratingOrder,
        workflow_state: workflowState,
      },
      rubric_association_id: rubricAssociationId,
      rubric_association: {
        id: rubricAssociationId,
        association_id: assignmentId ?? accountId ?? courseId,
        association_type: associationType,
        purpose: assignmentId ? 'grading' : undefined,
        hide_points: hidePoints ? 1 : 0,
        hide_outcome_results: hideOutcomeResults ? 1 : 0,
        hide_score_total: hideScoreTotal ? 1 : 0,
        use_for_grading: useForGrading ? 1 : 0,
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to save rubric: ${response.statusText}`)
  }

  const {rubric: savedRubric, rubric_association, error} = await response.json()

  if (error) {
    throw new Error(`Failed to save rubric`)
  }

  return {
    rubric: {
      ...mapRubricUnderscoredKeysToCamelCase(savedRubric),
      canUpdate: savedRubric.permissions?.update,
      association_count: savedRubric.association_count,
    },
    rubricAssociation: mapRubricAssociationUnderscoredKeysToCamelCase(rubric_association),
  }
}

export const generateCriteria = async (
  courseId: string,
  assignmentId: string,
  generateCriteriaProps: GenerateCriteriaFormProps,
): Promise<CanvasProgress> => {
  const url = `/courses/${courseId}/rubrics/llm_criteria`
  const method = 'POST'

  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: qs.stringify({
      _method: method,
      rubric_association: {
        association_id: assignmentId,
        association_type: 'Assignment',
      },
      generate_options: {
        criteria_count: generateCriteriaProps.criteriaCount,
        rating_count: generateCriteriaProps.ratingCount,
        points_per_criterion: generateCriteriaProps.pointsPerCriterion,
        use_range: generateCriteriaProps.useRange,
        additional_prompt_info: generateCriteriaProps.additionalPromptInfo,
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to generate criteria: ${response.statusText}`)
  }

  const progress: CanvasProgress = await response.json()
  return progress
}
