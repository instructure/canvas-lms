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

export interface Checkpoint {
  dueAt?: string
  name?: string
  tag?: string
}

export type ModuleItemContent = {
  id?: string
  _id?: string
  type?:
    | 'Assignment'
    | 'Quiz'
    | 'Discussion'
    | 'File'
    | 'Page'
    | 'ExternalUrl'
    | 'Attachment'
    | 'SubHeader'
    | 'ModuleExternalTool'
    | 'ExternalTool'
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
  replyToEntryRequiredCount?: number
  checkpoints?: Checkpoint[]
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
}

export interface ModuleRequirement {
  id: string | number
  type: string
  minScore?: number
  minPercentage?: number
  completed?: boolean
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

interface TeacherCourseSettings {
  showStudentOnlyModuleId: string
  showTeacherOnlyModuleId: string
}

interface StudentCourseSettings {
  showStudentOnlyModuleId?: string
}

interface CourseStudentResponse {
  name?: string
  submissionStatistics?: CoursesubmissionStatistics
  settings?: StudentCourseSettings
}

interface CourseStudentGraphQLResult {
  legacyNode?: {
    name?: string
    submissionStatistics?: CoursesubmissionStatistics
    settings?: StudentCourseSettings
  }
  errors?: {message: string}[]
}

interface CourseTeacherResponse {
  name?: string
  settings?: TeacherCourseSettings
}

interface CourseTeacherGraphQLResult {
  legacyNode?: {
    name?: string
    settings?: TeacherCourseSettings
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
  title: string
  indent: number
  position: number
  content: ModuleItemContent
  masterCourseRestrictions: ModuleItemMasterCourseRestrictionType | null
}

export type ModuleAction = 'move_module' | 'move_module_item' | 'move_module_contents'

export interface Folder {
  _id: string
  canUpload: boolean
  fullName: string
  id: string
  name: string
}

export type ExternalToolPlacementType =
  | 'module_group_menu'
  | 'module_menu_modal'
  | 'module_menu'
  | 'module_index_menu_modal'

export interface ExternalToolPlacement {
  message_type?: string
  url?: string
  title?: string
  selection_width?: number
  selection_height?: number
  launch_width?: number
  launch_height?: number
}

export interface ExternalToolTrayItem {
  id: string
  title: string
  base_url: string
  icon_url?: string | null
  canvas_icon_class?: string | null
}

export interface ExternalToolModalItem {
  definition_type: string
  definition_id: string | number
  url?: string
  name: string
  description?: string
  domain?: string | null
  placements: {
    assignment_selection?: ExternalToolPlacement
    link_selection?: ExternalToolPlacement
    module_group_menu?: ExternalToolPlacement
    module_menu_modal?: ExternalToolPlacement
    module_menu?: ExternalToolPlacement
    module_index_menu_modal?: ExternalToolPlacement
    [key: string]: ExternalToolPlacement | undefined
  }
}

export type ExternalTool = ExternalToolTrayItem | ExternalToolModalItem

export interface ExternalToolLaunchOptions {
  moduleId: string
  placement: ExternalToolPlacementType
  display?: 'borderless' | 'full'
  contextModuleId?: string
}

export interface ModuleItemMasterCourseRestrictionType {
  all: boolean | null
  availabilityDates: boolean | null
  content: boolean | null
  dueDates: boolean | null
  points: boolean | null
  settings: boolean | null
}
