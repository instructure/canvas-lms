/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type Rubric = {
  id: string
  criteria?: RubricCriterion[]
  criteriaCount: number
  hidePoints?: boolean
  locations: string[]
  buttonDisplay?: string
  ratingOrder?: string
  pointsPossible: number
  title: string
  workflowState?: string
  hasRubricAssociations?: boolean
}

export type RubricCriterion = {
  id: string
  points: number
  description: string
  longDescription: string
  ignoreForScoring?: boolean
  masteryPoints?: number
  criterionUseRange: boolean
  ratings: RubricRating[]
  learningOutcomeId?: string
}

export type RubricRating = {
  id: string
  description: string
  longDescription: string
  points: number
}

export type RubricAssessment = {
  id: string
  rubricId: string
  rubricAssociationId: string
  artifactType: string
  artifactId: string
  artifactOutcomeId: string
  assessmentType: string
  data: RubricAssessmentData[]
  workflowState: string
}

export type RubricAssessmentData = {
  id: string
  points?: number
  criterionId: string
  learningOutcomeId?: string
  comments: string
  commentsEnabled: boolean
  description: string
  saveCommentsForLater?: boolean
}

export type UpdateAssessmentData = {
  criterionId: string
  points?: number
  description?: string
  comments?: string
}
