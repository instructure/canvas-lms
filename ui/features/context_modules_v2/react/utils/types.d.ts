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

import {type Root} from 'react-dom/client'
import {NEW_ITEM_FIELDS} from '../utils/constants'

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
  assignedToDates?: StandardizedDateHash[]
  assignmentOverrides?: AssignmentOverrideGraphQLResult
}

export interface StandardizedDateHash {
  id?: string
  dueAt?: string
  unlockAt?: string
  lockAt?: string
  title?: string
  base?: boolean
  set?: {
    id?: string
    type?: string
  }
}

export type ExternalUrl = {
  url: string
  name: string
  newTab: boolean
  isUrlValid?: boolean
}

export type ExternalToolUrl = {
  url: string
  name: string
  newTab: boolean
  selectedToolId?: string
  isUrlValid?: boolean
}

export type NewItem = {
  name: string
  assignmentGroup: string
  file: File | null
  folder: string
}

export type FormState = {
  indentation: number
  textHeader: string
  externalUrl: ExternalUrl
  externalTool: ExternalToolUrl
  newItem: NewItem
  selectedItemId: string
  selectedItem: any | null
  selectedItemIds: string[]
  selectedItems: any[]
  tabIndex: number
  isLoading: boolean
}

// Add new menu actions here (e.g., 'delete', 'sendTo', 'copyTo')
type MenuAction = 'duplicate'

type PerModuleState<T> = Record<ModuleId, T>

type MenuItemActionState = {
  type: MenuAction
  state: boolean
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
  title?: string
  canUnpublish?: boolean
  canDuplicate?: boolean
  canManageAssignTo?: boolean
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
  assignedToDates?: StandardizedDateHash[]
  assignment?: {
    _id: string
    dueAt?: string
    assignmentOverrides?: AssignmentOverrideGraphQLResult
    assignedToDates?: StandardizedDateHash[]
  }
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
  score?: number
}

export interface ModuleProgression {
  id: string
  _id: string
  workflowState?: string
  completedAt?: string
  currentPosition?: number
  collapsed?: boolean
  requirementsMet: ModuleRequirement[]
  incompleteRequirements?: ModuleRequirement[]
  completed?: boolean
  locked?: boolean
  unlocked?: boolean
  started?: boolean
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
  moduleItemsTotalCount: number
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

export interface ModuleItem {
  id: string
  _id: string
  url: string
  moduleItemUrl: string | null
  title: string
  indent: number
  position: number
  content: ModuleItemContent
  masterCourseRestrictions: ModuleItemMasterCourseRestrictionType | null
  newTab?: boolean
  published?: boolean
  masteryPaths?: ModuleItemMasteryPath
}

export interface ModuleItemMasteryPath {
  awaitingChoice?: boolean
  chooseUrl?: string
  locked?: boolean
  stillProcessing?: boolean
  assignmentSetCount?: number
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
    assignmentSelection?: ExternalToolPlacement
    linkSelection?: ExternalToolPlacement
    moduleGroupMenu?: ExternalToolPlacement
    moduleMenuModal?: ExternalToolPlacement
    moduleMenu?: ExternalToolPlacement
    moduleIndexMenuModal?: ExternalToolPlacement
    [key: string]: ExternalToolPlacement | undefined
  }
}

export type ModuleCursorState = Record<string, string | null>

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

export interface GraphQLError {
  message: string
  [key: string]: any
}

export interface PageInfo {
  hasNextPage: boolean
  endCursor: string | null
}

interface LegacyNodeModuleItemsConnection {
  moduleItemsTotalCount?: number
  moduleItemsConnection?: {
    edges: Array<{
      cursor: string
      node: ModuleItem
    }>
    pageInfo: PageInfo
  }
}

export interface PaginatedNavigationResponse {
  moduleItems: ModuleItem[]
  pageInfo: PageInfo
}

interface PaginatedNavigationGraphQLResult {
  legacyNode?: LegacyNodeModuleItemsConnection
  errors?: GraphQLError[]
}

export type QuizEngine = 'new' | 'classic'

export type ModuleKBActionEvent = 'module-action'
export type ModuleKBAction = 'edit' | 'delete' | 'new'
export type ModuleItemKBAction = 'edit' | 'remove' | 'indent' | 'outdent'
export interface ModuleActionEventDetail {
  action: ModuleKBAction | ModuleItemKBAction
  courseId: string
  moduleId?: string
  moduleItemId?: string
  [key: string]: unknown
}

export type ModulePageNavigationEvent = 'module-page-navigation'
export interface ModulePageNavigationDetail {
  moduleId: string
  pageNumber: number
}

export interface HTMLElementWithRoot extends HTMLElement {
  reactRoot?: Root
}

export type DragStateChangeEvent = 'drag-state-change'
export interface DragStateChangeDetail {
  isDragging: boolean
}

declare global {
  interface Document {
    addEventListener(
      type: ModuleKBActionEvent,
      listener: (event: CustomEvent<ModuleActionEventDetail>) => void,
    ): void
    addEventListener(
      type: ModulePageNavigationEvent,
      listener: (event: CustomEvent<ModulePageNavigationDetail>) => void,
    ): void
    addEventListener(
      type: DragStateChangeEvent,
      listener: (event: CustomEvent<DragStateChangeDetail>) => void,
    ): void
    removeEventListener(
      type: ModuleKBActionEvent,
      listener: (event: CustomEvent<ModuleActionEventDetail>) => void,
    ): void
    removeEventListener(
      type: ModulePageNavigationEvent,
      listener: (event: CustomEvent<ModulePageNavigationDetail>) => void,
    ): void
    removeEventListener(
      type: DragStateChangeEvent,
      listener: (event: CustomEvent<DragStateChangeDetail>) => void,
    ): void
  }
}
