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

type Module = {
  id: string
  name?: string
}

type AssignmentGroup = {
  name?: string
}

type Group = {
  name?: string
  id?: string
  _id?: string
}

type GroupSet = {
  name?: string
  id?: string
  _id?: string
  currentGroup?: Group
}

type LockInfo = {
  isLocked: boolean
}

type MediaSource = {
  src?: string
  type?: string
}

type MediaObject = {
  id?: string
  title?: string
  mediaType?: string
  mediaSources?: MediaSource[]
}

type SubmissionFile = {
  _id?: string
  displayName?: string
  mimeClass?: string
  url?: string
}

type ExternalTool = {
  _id?: string
  name?: string
}

type SubmissionDraft = {
  activeSubmissionType?: string
  attachments?: SubmissionFile[]
  body?: string
  meetsAssignmentCriteria?: boolean
  meetsBasicLtiLaunchCriteria?: boolean
  meetsTextEntryCriteria?: boolean
  meetsUploadCriteria?: boolean
  meetsUrlCriteria?: boolean
  externalTool?: ExternalTool
  ltiLaunchUrl?: string
  resourceLinkLookupUuid?: string
}

type TurnitinData = {
  status?: string
  score?: number
  reportUrl?: string
}

type User = {
  _id?: string
  name?: string
  avatarUrl?: string
}

type AssessmentRequest = {
  anonymousId?: string
  anonymousUser?: boolean
  workflowState?: string
  assetId?: string
  assetSubmissionType?: string
  user?: User
}

export type Submission = {
  _id: string
  id: string
  attachment?: SubmissionFile
  attachments?: SubmissionFile[]
  attempt: number
  body?: string
  deductedPoints?: number
  enteredGrade?: string
  gradedAnonymously?: boolean
  hideGradeFromStudent?: boolean
  extraAttempts?: number
  grade?: string
  gradeHidden: boolean
  gradingStatus?: 'needs_grading' | 'excused' | 'needs_review' | 'graded'
  customGradeStatus?: string
  latePolicyStatus?: string
  mediaObject?: MediaObject
  originalityData?: Record<string, any>
  proxySubmitter?: string
  resourceLinkLookupUuid?: string
  score?: number
  state: string
  sticker?: string
  submissionDraft?: SubmissionDraft
  submissionStatus?: string
  submissionType?: string
  submittedAt?: string
  turnitinData?: TurnitinData[]
  feedbackForCurrentAttempt: boolean
  unreadCommentCount: number
  url?: string
  assignedAssessments?: AssessmentRequest[]
}

type SubmissionsConnection = {
  nodes: Submission[]
}

export type Assignment = {
  _id: string
  allowedAttempts?: number
  allowedExtensions?: string[]
  assignmentGroup?: AssignmentGroup
  description?: string
  dueAt?: string
  expectsSubmission: boolean
  gradingType?: string
  gradeGroupStudentsIndividually?: boolean
  groupCategoryId?: number
  groupSet?: GroupSet
  lockAt?: string
  lockInfo?: LockInfo
  modules?: Module[]
  name: string
  nonDigitalSubmission: boolean
  originalityReportVisibility?: string
  pointsPossible: number
  submissionTypes: string[]
  unlockAt?: string
  rubricSelfAssessmentEnabled?: boolean
  submissionsConnection?: SubmissionsConnection
  env: {
    courseId: string
    [key: string]: any
  }
}
