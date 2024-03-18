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

import type {Rubric, RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'

export type RubricTrayType = Pick<Rubric, 'title' | 'criteria' | 'ratingOrder'> | undefined
export type RubricUnderscoreType = {
  title: string
  criteria: {
    criterion_use_range: boolean
    description: string
    id: string
    long_description: string
    points: number
    ratings: {
      criterion_id: string
      description: string
      id: string
      long_description: string
      points: number
    }[]
  }[]
  rating_order: string
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
  rubric: RubricUnderscoreType
): RubricTrayType => {
  return {
    title: rubric.title,
    criteria: rubric.criteria.map(criterion => {
      return {
        criterionUseRange: criterion.criterion_use_range,
        description: criterion.description,
        id: criterion.id,
        longDescription: criterion.long_description,
        points: criterion.points,
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
  }
}

export const mapRubricAssessmentDataUnderscoredKeysToCamelCase = (
  data: RubricAssessmentDataUnderscore[]
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
