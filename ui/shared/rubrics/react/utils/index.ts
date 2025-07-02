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

import type {RubricAssessment} from '@canvas/grading/grading'
import type {
  Rubric,
  RubricAssessmentData,
  RubricAssociation,
  RubricRating,
} from '@canvas/rubrics/react/types/rubric'

export type RubricUnderscoreType = {
  title: string
  criteria: RubricUnderscoreCriteria[]
  data?: RubricUnderscoreCriteria[]
  id: string
  rating_order: string
  free_form_criterion_comments: boolean
  points_possible: number
  unassessed?: boolean
  workflow_state: string
}

type RubricUnderscoreCriteria = {
  criterion_use_range: boolean
  description: string
  id: string
  learning_outcome_id?: string
  long_description: string
  ignore_for_scoring?: boolean
  mastery_points?: number
  points: number
  ratings: {
    criterion_id: string
    description: string
    id: string
    long_description: string
    points: number
  }[]
}

export type RubricOutcomeUnderscore = {
  id: string
  display_name: string
}

export type RubricAssessmentUnderscore = RubricAssessment & {
  data: RubricAssessmentDataUnderscore[]
}

export type RubricAssessmentDataUnderscore = {
  id: string
  points: number
  criterion_id: string
  learning_outcome_id?: string
  comments: string
  comments_enabled: boolean
  description: string
}
export const mapRubricUnderscoredKeysToCamelCase = (
  rubric: RubricUnderscoreType,
  rubricOutcomeData: RubricOutcomeUnderscore[] = [],
): Rubric => {
  const rubricOutcomeMap = rubricOutcomeData.reduce(
    (prev, curr) => {
      prev[curr.id] = curr.display_name
      return prev
    },
    {} as Record<string, string>,
  )

  const criteria = rubric.criteria ?? rubric.data ?? []

  return {
    title: rubric.title,
    criteria: criteria.map(criterion => {
      const {learning_outcome_id} = criterion

      return {
        criterionUseRange: criterion.criterion_use_range,
        description: criterion.description,
        id: criterion.id,
        longDescription: criterion.long_description,
        learningOutcomeId: criterion.learning_outcome_id,
        ignoreForScoring: criterion.ignore_for_scoring,
        points: criterion.points,
        masteryPoints: criterion.mastery_points,
        outcome: learning_outcome_id
          ? {
              displayName: rubricOutcomeMap[learning_outcome_id],
              title: criterion.description,
            }
          : undefined,
        ratings: criterion.ratings.map(rating => {
          return {
            criterionId: rating.criterion_id,
            description: rating.description,
            id: rating.id,
            longDescription: rating.long_description,
            points: rating.points,
          }
        }),
      }
    }),
    ratingOrder: rubric.rating_order,
    freeFormCriterionComments: rubric.free_form_criterion_comments,
    pointsPossible: rubric.points_possible,
    criteriaCount: criteria.length,
    id: rubric.id,
    unassessed: rubric.unassessed,
    workflowState: rubric.workflow_state,
  }
}

export const mapRubricAssessmentDataUnderscoredKeysToCamelCase = (
  data: RubricAssessmentDataUnderscore[],
): RubricAssessmentData[] => {
  return data.map(assessment => {
    return {
      id: assessment.id,
      points: assessment.points,
      criterionId: assessment.criterion_id,
      learningOutcomeId: assessment.learning_outcome_id,
      comments: assessment.comments,
      commentsEnabled: assessment.comments_enabled,
      description: assessment.description,
    }
  })
}

export type RubricAssociationUnderscore = {
  id: string
  rubric_id: string
  use_for_grading: boolean
  hide_points: boolean
  hide_score_total: boolean
  hide_outcome_results: boolean
}
export const mapRubricAssociationUnderscoredKeysToCamelCase = (
  underscoreAssociation: RubricAssociationUnderscore,
): RubricAssociation => {
  return {
    id: underscoreAssociation.id,
    hideOutcomeResults: underscoreAssociation.hide_outcome_results,
    hidePoints: underscoreAssociation.hide_points,
    hideScoreTotal: underscoreAssociation.hide_score_total,
    useForGrading: underscoreAssociation.use_for_grading,
  }
}

type ReorderProps = {
  list: RubricRating[]
  startIndex: number
  endIndex: number
}

export const reorderRatingsAtIndex = ({list, startIndex, endIndex}: ReorderProps) => {
  const result = Array.from(list)
  const resultCopy = JSON.parse(JSON.stringify(list))

  const [removed] = result.splice(startIndex, 1)
  result.splice(endIndex, 0, removed)

  result.forEach((item, index) => {
    item.points = resultCopy[index].points
  })

  return result
}
