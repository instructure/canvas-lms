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

export interface Attachment {
  _id: string
  displayName: string
  mimeClass: string
  size: string
  thumbnailUrl?: string | null
  submissionPreviewUrl?: string | null
  url?: string | null
}

export interface Submission {
  _id: string
  attempt: number
  body?: string | null
  submissionType: string
  url?: string | null
  attachments?: Attachment[] | null
}

export interface PeerReviewDates {
  dueAt: string | null
  unlockAt: string | null
  lockAt: string | null
}

export interface AssignedToDates {
  dueAt: string | null
  peerReviewDates: PeerReviewDates | null
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
  submissionsConnection: SubmissionsConnection | null
  assignedToDates: AssignedToDates[] | null
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
  submissionRequired: boolean | null
}

interface SubmissionsConnection {
  nodes: SubmissionNode[] | null
}

interface SubmissionNode {
  _id: string
  submissionStatus: string | null
}

export interface ReviewerSubmission {
  _id: string
  id: string
  attempt: number
  assignedAssessments: {
    assetId: string
    workflowState: string
    assetSubmissionType: string | null
  }[]
}
