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

export type CourseType = {
  lid: string
}

export type ModuleType = {
  lid: string
  name: string
}

export type ModuleItemType = {
  lid: string
  title: string
}

export type AssignmentGroupType = {
  lid: string
  name: string
}

export type LockInfoType = {
  isLocked: boolean
}

export type peerReviewsType = {
  enabled: boolean
}

type SetType = {
  lid?: string
  name?: string
  __typename?: 'Section' | 'Group' | 'AdhocStudents'
}

export type OverrideType = {
  id?: string
  lid?: string
  title?: string
  dueAt?: string
  lockAt?: string
  unlockAt?: string
  submissionTypes?: string[]
  allowedAttempts?: number
  allowedExtensions?: string[]
  set?: SetType
}

export type UserType = {
  lid?: string
  gid?: string
  name?: string
  shortName?: string
  sortableName?: string
  avatarUrl?: string
  email?: string
}

export type SubmissionHistoryType = {
  attempt?: number
  score?: number
  submittedAt?: string
}

export type SubmissionDraftType = {
  submissionAttempt?: string
}

type SubmissionHistoriesConnectionType = {
  nodes?: SubmissionHistoryType[]
}

export type SubmissionType = {
  gid?: string
  lid?: string
  attempt?: number
  submissionStatus?: 'resubmitted' | 'missing' | 'late' | 'submitted' | 'unsubmitted'
  grade?: string
  gradingStatus?: null | 'excused' | 'needs_review' | 'needs_grading' | 'graded'
  score?: number
  state?: 'submitted' | 'unsubmitted' | 'pending_review' | 'graded' | 'deleted'
  excused?: boolean
  latePolicyStatus?: null | 'missing'
  submittedAt?: string
  user?: UserType
  submissionHistoriesConnection?: SubmissionHistoriesConnectionType
  submissionDraft?: SubmissionDraftType
}

type PageInfoType = {
  startCursor?: string
  endCursor?: string
  hasNextPage?: boolean
  hasPreviousPage?: boolean
}

type AssignmentOverridesType = {
  pageInfo: PageInfoType
  nodes: OverrideType[]
}

type SubmissionsType = {
  pageInfo: PageInfoType
  nodes: SubmissionType[]
}

export type TeacherAssignmentType = {
  __typename?: string
  id: string
  gid?: string
  lid?: string
  name?: string
  pointsPossible?: number | string
  dueAt?: string
  lockAt?: string
  unlockAt?: string
  description?: string
  state?: 'published' | 'unpublished' | 'deleted'
  totalSubmissions?: number
  totalGradedSubmissions?: number
  totalUngradedSubmissions?: number
  needsGradingCount?: number
  onlyVisibleToOverrides?: boolean
  assignmentGroup?: AssignmentGroupType
  modules?: ModuleType[]
  moduleItems?: ModuleItemType[]
  course: CourseType
  lockInfo?: LockInfoType
  peerReviews?: peerReviewsType
  submissionTypes?: string[]
  allowedExtensions?: string[]
  allowedAttempts?: number
  anonymizeStudents?: boolean
  assignmentOverrides?: AssignmentOverridesType
  hasSubmittedSubmissions?: boolean
  submissionsDownloads?: number
  submissions?: SubmissionsType
  suppressAssignment?: boolean
}

export interface CreateAllocationRuleInput {
  assignmentId: string
  assessorIds: string[]
  assesseeIds: string[]
  mustReview?: boolean
  reviewPermitted?: boolean
  appliesToAssessor?: boolean
  reciprocal?: boolean
}

export type AllocationRuleType = {
  _id: string
  assessor: UserResponse
  assessee: UserResponse
  mustReview: boolean
  reviewPermitted: boolean
  appliesToAssessor: boolean
}

export interface CreateAllocationRuleResponse {
  createAllocationRule: {
    allocationRules: AllocationRuleType[]
    allocationErrors: Array<{
      message: string
      attribute: string
      attributeId: string
    }>
  }
}

interface UserResponse {
  _id: string
  name: string
}

export interface UpdateAllocationRuleInput {
  ruleId: string
  assessorIds: string[]
  assesseeIds: string[]
  mustReview: boolean
  reviewPermitted: boolean
  appliesToAssessor: boolean
  reciprocal: boolean
}

export interface UpdateAllocationRuleResponse {
  updateAllocationRule: {
    allocationRules: Array<{
      _id: string
      mustReview: boolean
      reviewPermitted: boolean
      appliesToAssessor: boolean
      assessor: {
        _id: string
        name: string
      }
      assessee: {
        _id: string
        name: string
      }
    }>
    allocationErrors: Array<{
      attributeId: string
      message: string
    }>
  }
}
