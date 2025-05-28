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

export interface MasteryPathsData {
  isCyoeAble: boolean
  isTrigger: boolean
  isReleased: boolean
  releasedLabel: string | null
}

export type ModuleItemContent = {
  id?: string
  _id?: string
  title: string
  type?:
    | 'Assignment'
    | 'Quiz'
    | 'Discussion'
    | 'File'
    | 'Page'
    | 'ExternalUrl'
    | 'Attachment'
    | 'SubHeader'
  pointsPossible?: number
  published?: boolean
  canUnpublish?: boolean
  canDuplicate?: boolean
  dueAt?: string
  lockAt?: string
  unlockAt?: string
  cachedDueDate?: string
  todoDate?: string
  submissionsConnection?: {
    nodes: Array<{
      _id: string
      cachedDueDate?: string
      missing?: boolean
    }>
  }
  url?: string
  isLockedByMasterCourse?: boolean
  assignmentGroupId?: string
  submissionTypes?: string[]
  discussionType?: string
  displayName?: string
  contentType?: string
  size?: string
  thumbnailUrl?: string
  externalUrl?: string
  newTab?: boolean
  fileState?: string
  locked?: boolean
  graded?: boolean
  assignmentOverrides?: AssignmentOverrideGraphQLResult
  isNewQuiz?: boolean
} | null

interface AssignmentOverrideGraphQLResult {
  edges: Array<{
    cursor: string
    node: AssignmentOverride
  }>
}

export interface AssignmentOverride {
  dueAt?: string
  set: {
    students?: Array<{
      id: string
    }>
    sectionId?: string
    courseId?: string
    groupId?: string
  }
}

export type DueAtCount = {
  groups?: number
  sections?: number
  students?: number
}

export type DueAtCounts = {
  [key: string]: DueAtCount
}

export interface CompletionRequirement {
  id: string
  type: string
  minScore?: number
  minPercentage?: number
  completed?: boolean
  fulfillmentStatus?: string
}

export interface ModuleRequirement {
  id: string | number
  type: string
  min_score?: number
  min_percentage?: number
  score?: number
}

export interface ModuleProgression {
  id: string
  _id: string
  workflowState: string
  completedAt?: string
  currentPosition?: number
  collapsed?: boolean
  requirementsMet: ModuleRequirement[]
  incompleteRequirements?: ModuleRequirement[]
  current?: boolean
  evaluatedAt?: string
  completed: boolean
  locked: boolean
  unlocked: boolean
  started: boolean
}

export interface Prerequisite {
  id: string
  type: string
  name: string
}

export interface ModuleStatistics {
  latestDueAt: string | null
  missingAssignmentCount: number
}

export interface Module {
  id: string
  _id: string
  name: string
  position: number
  published: boolean
  prerequisites: Prerequisite[]
  completionRequirements: CompletionRequirement[]
  requirementCount: number
  requireSequentialProgress: boolean
  unlockAt: string | null
  moduleItems: ModuleItem[]
  progression?: ModuleProgression
  hasActiveOverrides: boolean
  submissionStatistics?: ModuleStatistics
}

export interface ModulesResponse {
  modules: Module[]
  courseName?: string
  pageInfo: {
    hasNextPage: boolean
    endCursor: string | null
  }
}

interface CoursesubmissionStatistics {
  submissionsDueThisWeekCount: number
  missingSubmissionsCount: number
}

interface CourseStudentResponse {
  name?: string
  submissionStatistics?: CoursesubmissionStatistics
}

interface CourseStudentGraphQLResult {
  legacyNode?: {
    name?: string
    submissionStatistics?: CoursesubmissionStatistics
  }
  errors?: {message: string}[]
}

interface GraphQLResult {
  legacyNode?: {
    modulesConnection?: {
      edges: Array<{
        cursor: string
        node: Module
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
  }
  errors?: Array<{
    message: string
    [key: string]: any
  }>
}

export interface ModuleItemsResponse {
  moduleItems: ModuleItem[]
}

interface ModuleItemsGraphQLResult {
  legacyNode?: {
    moduleItems?: ModuleItem[]
  }
  errors?: Array<{
    message: string
    [key: string]: any
  }>
}

export interface ModuleItem {
  id: string
  _id: string
  url: string
  indent: number
  position: number
  content: ModuleItemContent
}

export type ModuleAction = 'move_module' | 'move_module_item' | 'move_module_contents'

export interface Folder {
  _id: string
  canUpload: boolean
  fullName: string
  id: string
  name: string
}
