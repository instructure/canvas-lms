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

import getCookie from '@instructure/get-cookie'
import {gql} from '@apollo/client'
import qs from 'qs'
import type {GradingRubricContext} from '../types/rubricAssignment'
import type {Rubric, RubricAssociation} from '../../types/rubric'
import {
  mapRubricUnderscoredKeysToCamelCase,
  mapRubricAssociationUnderscoredKeysToCamelCase,
} from '../../utils'
import type {QueryOptions} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'

export const removeRubricFromAssignment = async (courseId: string, rubricAssociationId: string) => {
  return fetch(`/courses/${courseId}/rubric_associations/${rubricAssociationId}`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    method: 'POST',
    body: qs.stringify({
      _method: 'DELETE',
    }),
  })
}

export type AssignmentRubric = Rubric & {can_update?: boolean; association_count?: number}
export const addRubricToAssignment = async (
  courseId: string,
  assignmentId: string,
  rubricId: string,
  updatedAssociation: RubricAssociation,
) => {
  const {hidePoints, hideOutcomeResults, hideScoreTotal, useForGrading} = updatedAssociation

  const response = await fetch(`/courses/${courseId}/rubric_associations`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    method: 'POST',
    body: qs.stringify({
      _method: 'POST',
      rubric_association: {
        association_type: 'Assignment',
        association_id: assignmentId,
        rubric_id: rubricId,
        purpose: 'grading',
        hide_points: hidePoints ? 1 : 0,
        hide_outcome_results: hideOutcomeResults ? 1 : 0,
        hide_score_total: hideScoreTotal ? 1 : 0,
        use_for_grading: useForGrading ? 1 : 0,
      },
    }),
  })

  if (!response.ok) {
    throw new Error('Failed to add rubric to assignment')
  }

  const result = await response.json()

  const mappedRubric = mapRubricUnderscoredKeysToCamelCase(result.rubric)

  return {
    rubricAssociation: result.rubric_association,
    rubric: {
      ...mappedRubric,
      can_update: result.rubric.permissions?.update,
      association_count: result.rubric.association_count,
    } as AssignmentRubric,
  }
}

export const getGradingRubricContexts = async ({
  queryKey,
}: QueryOptions): Promise<GradingRubricContext[]> => {
  if (!queryKey) {
    throw Error('Query key is required')
  }

  const [_, courseId] = queryKey

  const contexts = await fetch(`/courses/${courseId}/grading_rubrics`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!contexts.ok) {
    throw new Error('Failed to get grading rubric contexts')
  }

  return (await contexts.json()) as GradingRubricContext[]
}

type GradingRubricForContextResponse = {
  rubricAssociation: RubricAssociation
  rubric: Rubric
}
export const getGradingRubricsForContext = async ({
  queryKey,
}: QueryOptions): Promise<GradingRubricForContextResponse[]> => {
  if (!queryKey) {
    throw Error('Query key is required')
  }

  const [_, courseId, contextCode] = queryKey

  if (!contextCode) {
    throw Error('Context code is required')
  }

  const contexts = await fetch(`/courses/${courseId}/grading_rubrics?context_code=${contextCode}`, {
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
    },
  })

  if (!contexts.ok) {
    throw new Error('Failed to get grading rubric contexts')
  }

  const results = await contexts.json()

  return results.map((result: {rubric_association: any}) => {
    return {
      rubricAssociation: mapRubricAssociationUnderscoredKeysToCamelCase(result.rubric_association),
      rubric: mapRubricUnderscoredKeysToCamelCase(result.rubric_association?.rubric),
    }
  })
}

const SET_RUBRIC_SELF_ASSESSMENT = gql`
  mutation SetRubricSelfAssessment($assignmentId: ID!, $enabled: Boolean!) {
    setRubricSelfAssessment(
      input: {assignmentId: $assignmentId, rubricSelfAssessmentEnabled: $enabled}
    ) {
      errors {
        attribute
        message
      }
    }
  }
`

type SelfAssessmentResponse = {
  setRubricSelfAssessment: {
    errors: {
      attribute: string
      message: string
    }[]
  }
}
export const setRubricSelfAssessment = async ({
  assignmentId,
  enabled,
}: {
  assignmentId: string
  enabled: boolean
}) => {
  const {
    setRubricSelfAssessment: {errors},
  } = await executeQuery<SelfAssessmentResponse>(SET_RUBRIC_SELF_ASSESSMENT, {
    assignmentId,
    enabled,
  })

  if (errors) {
    throw new Error('Failed to set rubric self assessment on assignment')
  }
}

export const ASSIGNMENT_RUBRIC_SELF_ASSESSMENTS_QUERY = gql`
  query GetAssignmentRubricSelfAssessmentSettings($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      canUpdateRubricSelfAssessment
      rubricSelfAssessmentEnabled
    }
  }
`
type RubricSelfAssessmentSettingsParams = {
  queryKey: (string | number)[]
}
type RubricSelfAssessmentSettingsResponse = {
  assignment: {
    canUpdateRubricSelfAssessment: boolean
    rubricSelfAssessmentEnabled: boolean
  }
}
export const getRubricSelfAssessmentSettings = async ({
  queryKey,
}: RubricSelfAssessmentSettingsParams) => {
  const [_, assignmentId] = queryKey
  const {
    assignment: {canUpdateRubricSelfAssessment, rubricSelfAssessmentEnabled},
  } = await executeQuery<RubricSelfAssessmentSettingsResponse>(
    ASSIGNMENT_RUBRIC_SELF_ASSESSMENTS_QUERY,
    {
      assignmentId,
    },
  )

  return {
    canUpdateRubricSelfAssessment,
    rubricSelfAssessmentEnabled,
  }
}
