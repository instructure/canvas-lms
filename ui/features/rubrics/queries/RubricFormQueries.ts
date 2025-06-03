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
import type {RubricFormProps} from '../types/RubricForm'
import type {Rubric, RubricAssociation} from '@canvas/rubrics/react/types/rubric'
import {mapRubricUnderscoredKeysToCamelCase} from '@canvas/rubrics/react/utils'
import getCookie from '@instructure/get-cookie'

const RUBRIC_QUERY = gql`
  query FeaturesRubricQuery($id: ID!) {
    rubric(id: $id) {
      id: _id
      title
      hasRubricAssociations
      hidePoints
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
}

type FetchRubricResponse = {
  rubric: RubricQueryResponse
}

export const fetchRubric = async (id?: string): Promise<RubricQueryResponse | null> => {
  if (!id) return null

  const {rubric} = await executeQuery<FetchRubricResponse>(RUBRIC_QUERY, {
    id,
  })
  return rubric
}

export type SaveRubricResponse = {
  rubric: Rubric & {association_count?: number}
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
  } = rubric
  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  const url = `${urlPrefix}/rubrics/${id ?? ''}`
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
        free_form_comments: freeFormCriterionComments,
        criteria,
        button_display: buttonDisplay,
        rating_order: ratingOrder,
        workflow_state: workflowState,
      },
      rubric_association: {
        association_id: assignmentId ?? accountId ?? courseId,
        association_type: assignmentId ? 'Assignment' : accountId ? 'Account' : 'Course',
        purpose: assignmentId ? 'grading' : undefined,
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
    rubric: {...mapRubricUnderscoredKeysToCamelCase(savedRubric), association_count: 1},
    rubricAssociation: rubric_association,
  }
}
