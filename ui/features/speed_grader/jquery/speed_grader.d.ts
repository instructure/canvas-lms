/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

interface Window {
  jsonData: any
}

export type Grade = {
  entered: string
  pointsDeducted?: any
  adjusted?: any
}

export type GradingError = {
  errors?: {
    error_code:
      | 'ASSIGNMENT_LOCKED'
      | 'MAX_GRADERS_REACHED'
      | 'PROVISIONAL_GRADE_INVALID_SCORE'
      | 'PROVISIONAL_GRADE_MODIFY_SELECTED'
  }
}

export type StudentWithSubmission = {
  submission_state: 'graded' | 'not_graded' | 'not_submitted' | 'not_gradeable'
  submission: Submission
}

export type TurnitinAsset = {
  status: string
  provider: string
  similarity_score?: number
  state?: string
  public_error_message?: string
}

export type Submission = {
  attempt?: number
  excused?: boolean
  graded_at: string | null
  has_originality_score?: any
  id?: string
  late?: boolean
  score?: number
  submission_type?: string
  turnitin_data?: TurnitinAsset
  versioned_attachments?: any
  word_count?: number
}

export type RubricAssessment = {
  id: string
  assessor_id: string
  anonymous_assessor_id: string
  assessment_type: string
}

export type Attachment = {
  canvadoc_url?: string
  content_type: string
  crocodoc_url?: string
  display_name: string
  filename: string
  id: string
  mime_class: string
  provisional_canvadoc_url?: null | string
  provisional_crocodoc_url?: null | string
  upload_status: string
  viewed_at: string
  word_count: number
}

type GradeLoadingStateMap = {
  [userId: string]: boolean
}

export type GradeLoadingData = {
  currentStudentId: string
  gradesLoading: GradeLoadingStateMap
}
