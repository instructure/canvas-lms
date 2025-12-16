/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export interface Submission {
  _id: string
  attempt: number
  body?: string | null
  submissionType: string
}

export interface Assignment {
  _id: string
  name: string
  dueAt: string | null
  description: string | null
  expectsSubmission: boolean
  nonDigitalSubmission: boolean
  pointsPossible: number
  courseId: string
  peerReviews: PeerReviews | null
  assessmentRequestsForCurrentUser: AssessmentRequest[] | null
  env?: {
    currentUser?: {
      avatar_image_url?: string
      display_name?: string
    }
    courseId?: string
  }
}

export interface AssessmentRequest {
  _id: string
  available: boolean | null
  workflowState: string
  createdAt: string
  submission: Submission | null
}

interface PeerReviews {
  count: number | null
}
