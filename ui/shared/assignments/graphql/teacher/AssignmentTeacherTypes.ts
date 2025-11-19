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

export type PeerReviewsType = {
  count: number
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
  peerReviews?: PeerReviewsType
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
  assessor: CourseStudent
  assessee: CourseStudent
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

export interface CourseStudent {
  _id: string
  name: string
  peerReviewStatus: {
    mustReviewCount: number
    completedReviewsCount: number
  }
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
      assessor: CourseStudent
      assessee: CourseStudent
    }>
    allocationErrors: Array<{
      attributeId: string
      message: string
    }>
  }
}

export interface DeleteAllocationRuleInput {
  ruleId: string
}

export interface DeleteAllocationRuleResponse {
  deleteAllocationRule: {
    allocationRuleId: string
  }
}

export interface CourseStudentsData {
  course: {
    usersConnection: {
      nodes: CourseStudent[]
    }
  }
}

export interface CourseStudentsVariables {
  courseId: string
  filter?: {
    searchTerm?: string
    excludeTestStudents: boolean
  }
}

export interface AssignedStudentsData {
  assignment: {
    assignedStudents: {
      nodes: CourseStudent[]
    }
  }
}

export interface AssignedStudentsVariables {
  assignmentId: string
  filter?: {
    searchTerm?: string
  }
}

export interface AllocationRulesData {
  assignment: {
    allocationRules: {
      rulesConnection: {
        nodes: AllocationRuleType[]
        pageInfo: {
          hasNextPage: boolean
          endCursor: string | null
        }
      }
      count: number | null
    }
  }
}

export interface GraphQLPageData {
  rules: AllocationRuleType[]
  hasNextPage: boolean
  endCursor: string | null
  totalCount: number | null
}

export interface UseAllocationRulesResult {
  rules: AllocationRuleType[]
  totalCount: number | null
  loading: boolean
  error: any
  refetch: (page: number) => Promise<{rules: AllocationRuleType[]; totalCount: number | null}>
}
