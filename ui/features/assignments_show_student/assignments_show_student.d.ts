/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export type Enrollment = {
  type: string
  __typename: string
}

export type Assessor = {
  enrollments: Enrollment[]
  name: string
  __typename: string
  _id: string
}

export type Points = {
  text: string | null
  valid: boolean
  value: number | null
}

export type AssessmentData = {
  artifactAttempt: number
  comments: string | null
  comments_html: string | null
  criterion_id: string
  description: string
  editComments?: boolean
  id: string
  learning_outcome_id: string | null
  points: Points | number | null
  __typename: string
  _id: string
}

export type RubricAssociation = {
  hide_points: boolean
  hide_score_total: boolean
  use_for_grading: boolean
  __typename: string
  _id: string
}

export type Assessment = {
  artifactAttempt: number
  assessment_type: string
  assessor: Assessor
  data: AssessmentData[]
  rubric_association: RubricAssociation
  score: number | null
  __typename: string
  _id: string
}

export type RubricsStore = {
  displayedAssessment: Assessment | null
}
