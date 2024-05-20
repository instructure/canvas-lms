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

import {SubmissionOriginalityData} from '@canvas/grading/grading'
import {LatePolicyStatus, AssignmentGroup, Attachment, GradingType, MediaObject, Module} from 'api'

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

export type Assignment = {
  _id: string
  allowedAttempts: number | null
  allowedExtensions: string[]
  assignmentGroup: AssignmentGroup
  description: string
  dueAt: string | null
  env: Env
  expectsSubmission: boolean
  gradeGroupStudentsIndividually: boolean
  gradingType: GradingType
  groupCategoryId: number
  groupSet?: {
    currentGroup: {
      _id: string
    }
  }
  lockAt: string | null
  lockInfo: {
    isLocked: boolean
  }
  modules: Module[]
  name: string
  nonDigitalSubmission: boolean
  originalityReportVisibility: string | null
  pointsPossible: number
  submissionTypes: string[]
  unlockAt: string | null
}

export type Env = {
  assignmentUrl: string
  courseId: string
  currentUser: {
    id: string
    anonymous_id: string
    display_name: string
    avatar_image_url: string
    html_url: string
    pronouns: null | string
  }
  enrollmentState: string
  unlockDate: string | null
  modulePrereq: {
    title: string
    link: string
  } | null
  moduleUrl: string
  belongsToUnpublishedModule: boolean
  originalityReportsForA2Enabled: boolean
  peerReviewModeEnabled: boolean
  peerReviewAvailable: boolean
  peerDisplayName: string
  revieweeId?: string | number
  anonymousAssetId?: string | number
}

export type Submission = {
  _id: string
  assignedAssessments: number | null
  attachment: Attachment | null
  attachments: Attachment[]
  attempt: number | null
  body: string | null
  customGradeStatus: string | null
  deductedPoints: string | number | null
  enteredGrade: string | null
  extraAttempts: number | null
  feedbackForCurrentAttempt: boolean
  grade: string | null
  gradeHidden: boolean
  gradedAnonymously: boolean | null
  gradingStatus: string | null
  hideGradeFromStudent: boolean
  id: string
  latePolicyStatus: LatePolicyStatus | null
  mediaObject: MediaObject | null
  originalityData: {
    [key: string]: SubmissionOriginalityData
  }
  proxySubmitter: string | null
  resourceLinkLookupUuid: string | null
  score: number | null
  state: string
  submissionDraft: null
  submissionStatus: string | null
  submissionType: string
  submittedAt: string | null
  unreadCommentCount: number
}
