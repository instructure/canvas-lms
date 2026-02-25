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
import type {Rubric, RubricAssociation, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {
  mapRubricAssociationUnderscoredKeysToCamelCase,
  mapRubricUnderscoredKeysToCamelCase,
  decodeHTML,
} from '@canvas/rubrics/react/utils'
import getCookie from '@instructure/get-cookie'
import {
  SharedAccountRubricQueryQuery,
  SharedCourseRubricQueryQuery,
} from '@canvas/graphql/codegen/graphql'

const RUBRIC_FORM_RUBRIC_FRAGMENT = gql`
  fragment RubricFormRubric on Rubric {
    id: _id
    title
    hasRubricAssociations
    rubricAssociationForContext {
      associationId
      associationType
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
    canUpdateRubric
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
`

const COURSE_RUBRIC_QUERY = gql`
  query SharedCourseRubricQuery($courseId: ID!, $rubricId: ID!) {
    course(id: $courseId) {
      rubricsConnection(id: $rubricId) {
        nodes {
          ...RubricFormRubric
        }
      }
    }
  }
  ${RUBRIC_FORM_RUBRIC_FRAGMENT}
`
const ACCOUNT_RUBRIC_QUERY = gql`
  query SharedAccountRubricQuery($accountId: ID!, $rubricId: ID!) {
    account(id: $accountId) {
      rubricsConnection(id: $rubricId) {
        nodes {
          ...RubricFormRubric
        }
      }
    }
  }
  ${RUBRIC_FORM_RUBRIC_FRAGMENT}
`

type AccountRubricQueryResponse = SharedAccountRubricQueryQuery['account']
type CourseRubricQueryResponse = SharedCourseRubricQueryQuery['course']
export type RubricQueryResponse = NonNullable<
  NonNullable<
    NonNullable<
      NonNullable<AccountRubricQueryResponse | CourseRubricQueryResponse>['rubricsConnection']
    >['nodes']
  >[number]
>

type FetchRubricParams = {
  queryKey: string[]
}

export const fetchRubric = async ({
  queryKey,
}: FetchRubricParams): Promise<RubricQueryResponse | null> => {
  const [_, rubricId, accountId, courseId] = queryKey
  if (!rubricId) return null

  if (!accountId && !courseId) {
    throw new Error('Missing context for fetching rubric')
  }

  return accountId
    ? await fetchAccountRubric(accountId, rubricId)
    : await fetchCourseRubric(courseId, rubricId)
}

export const fetchAccountRubric = async (
  accountId: string,
  rubricId: string,
): Promise<RubricQueryResponse | null> => {
  const {account} = await executeQuery<SharedAccountRubricQueryQuery>(ACCOUNT_RUBRIC_QUERY, {
    accountId,
    rubricId,
  })
  return (account?.rubricsConnection?.nodes?.[0] ?? null) as RubricQueryResponse | null
}

export const fetchCourseRubric = async (
  courseId: string,
  rubricId: string,
): Promise<RubricQueryResponse | null> => {
  const {course} = await executeQuery<SharedCourseRubricQueryQuery>(COURSE_RUBRIC_QUERY, {
    courseId,
    rubricId,
  })
  return (course?.rubricsConnection?.nodes?.[0] ?? null) as RubricQueryResponse | null
}

export type SaveRubricResponse = {
  rubric: Rubric & {canUpdate?: boolean; association_count?: number}
  rubricAssociation?: RubricAssociation
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
    skipUpdatingPointsPossible,
  } = rubric

  const urlPrefix = accountId ? `/accounts/${accountId}` : `/courses/${courseId}`
  let url = `${urlPrefix}/rubrics/${id ?? ''}`

  const isAssignment = rubric.associationType === 'Assignment'

  if (isAssignment) {
    url = `${url}?rubric_association_id=${rubricAssociationId}`
  }
  const method = id ? 'PATCH' : 'POST'

  const criteria = rubric.criteria.map(criterion => {
    /**
     * remove all <br/> from the longDescription because the backend
     * html sanitization will escape any <br/> tags
     */
    const longDescription = criterion.outcome
      ? criterion.longDescription
      : // unescape any escaped html entities
        decodeHTML(criterion.longDescription?.replace(/<br\/>/g, '') ?? '')

    return {
      id: criterion.id,
      description: criterion.description,
      long_description: longDescription,
      points: criterion.points,
      outcome: {
        display_name: criterion.outcome?.displayName,
        title: criterion.outcome?.title,
      },
      learning_outcome_id: criterion.learningOutcomeId,
      ignore_for_scoring: criterion.ignoreForScoring,
      mastery_points: criterion.masteryPoints,
      criterion_use_range: criterion.criterionUseRange,
      generated: criterion.isGenerated,
      ratings: criterion.ratings.map(rating => ({
        description: rating.description,
        long_description: rating.longDescription,
        points: rating.points,
        id: rating.id,
      })),
    }
  })

  let rubricAssociationTypeId = rubric.associationTypeId

  if (!rubricAssociationTypeId) {
    if (rubric.associationType === 'Assignment') {
      rubricAssociationTypeId = assignmentId
    } else if (rubric.associationType === 'Course') {
      rubricAssociationTypeId = courseId
    } else if (rubric.associationType === 'Account') {
      rubricAssociationTypeId = accountId
    }
  }

  if (!rubricAssociationTypeId) {
    throw new Error('Missing rubric association type ID')
  }

  const response = await fetch(url, {
    method,
    headers: {
      'X-CSRF-Token': getCookie('_csrf_token'),
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
    body: qs.stringify({
      _method: method,
      rubric: {
        title: title.trim(),
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
        association_id: rubricAssociationTypeId,
        association_type: rubric.associationType,
        purpose: rubric.associationType === 'Assignment' ? 'grading' : 'bookmark',
        hide_points: hidePoints ? 1 : 0,
        hide_outcome_results: hideOutcomeResults ? 1 : 0,
        hide_score_total: hideScoreTotal ? 1 : 0,
        use_for_grading: useForGrading ? 1 : 0,
      },
      skip_updating_points_possible: skipUpdatingPointsPossible,
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
    rubricAssociation: rubric_association
      ? mapRubricAssociationUnderscoredKeysToCamelCase(rubric_association)
      : undefined,
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
        total_points: generateCriteriaProps.totalPoints,
        use_range: generateCriteriaProps.useRange,
        additional_prompt_info: generateCriteriaProps.additionalPromptInfo,
        grade_level: generateCriteriaProps.gradeLevel,
        standard: generateCriteriaProps.standard,
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to generate criteria: ${response.statusText}`)
  }

  const progress: CanvasProgress = await response.json()
  return progress
}

export const regenerateCriteria = async (
  courseId: string,
  assignmentId: string,
  criteriaForRegeneration: RubricCriterion[],
  additionalPrompt: string,
  criterionId?: string,
  generateFormOptions?: Partial<GenerateCriteriaFormProps>,
): Promise<CanvasProgress> => {
  const url = `/courses/${courseId}/rubrics/llm_regenerate_criteria`
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
      criteria: criteriaForRegeneration.map(criterion => ({
        id: criterion.id,
        description: criterion.description,
        long_description: criterion.longDescription,
        points: criterion.points,
        criterion_use_range: criterion.criterionUseRange,
        learning_outcome_id: criterion.learningOutcomeId,
        ignore_for_scoring: criterion.ignoreForScoring,
        mastery_points: criterion.masteryPoints,
        generated: criterion.isGenerated,
        ratings: criterion.ratings.map(rating => ({
          id: rating.id,
          criterion_id: criterion.id,
          description: rating.description,
          long_description: rating.longDescription,
          points: rating.points,
        })),
      })),
      generate_options: {
        criteria_count: generateFormOptions?.criteriaCount,
        rating_count: generateFormOptions?.ratingCount,
        total_points: generateFormOptions?.totalPoints,
        use_range: generateFormOptions?.useRange,
        grade_level: generateFormOptions?.gradeLevel,
        standard: generateFormOptions?.standard,
      },
      regenerate_options: {
        criterion_id: criterionId,
        additional_user_prompt: additionalPrompt,
      },
    }),
  })

  if (!response.ok) {
    throw new Error(`Failed to regenerate criteria: ${response.statusText}`)
  }

  const progress: CanvasProgress = await response.json()
  return progress
}
