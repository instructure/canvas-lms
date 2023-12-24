/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

type RequirementType = 'view' | 'mark' | 'submit' | 'score' | 'contribute'

type ResourceType =
  | 'assignment'
  | 'quiz'
  | 'file'
  | 'page'
  | 'discussion'
  | 'externalUrl'
  | 'externalTool'

export interface Module {
  id: string
  name: string
}

export interface ModuleItem extends Module {
  resource: ResourceType
}

export interface AssignmentOverride {
  context_module_id: string
  id: string
  students: {
    id: string
    name: string
  }[]
  course_section: {
    id: string
    name: string
  }
}

interface SectionOverride {
  id?: string
  course_section_id: string
}

interface StudentsOverride {
  id?: string
  student_ids: string[]
}

export type AssignmentOverridePayload = SectionOverride | StudentsOverride

export type AssignmentOverridesPayload = {
  overrides: AssignmentOverridePayload[]
}

export type DateDetailsOverride = AssignmentOverridePayload & {
  due_at: string | null
  unlock_at: string | null
  lock_at: string | null
}

interface BaseRequirement extends ModuleItem {
  type: RequirementType
}

interface AssignmentRequirement extends BaseRequirement {
  resource: 'assignment'
  type: Extract<RequirementType, 'view' | 'mark' | 'submit' | 'score'>
  minimumScore: string
  pointsPossible: null | string
}

interface QuizRequirement extends BaseRequirement {
  resource: 'quiz'
  type: Extract<RequirementType, 'view' | 'submit' | 'score'>
  minimumScore: string
  pointsPossible: null | string
}

interface FileRequirement extends BaseRequirement {
  resource: 'file'
  type: Extract<RequirementType, 'view'>
}

interface PageRequirement extends BaseRequirement {
  resource: 'page'
  type: Extract<RequirementType, 'view' | 'mark' | 'contribute'>
}

interface DiscussionRequirement extends BaseRequirement {
  resource: 'discussion'
  type: Extract<RequirementType, 'view' | 'contribute'>
}

interface ExternalUrlRequirement extends BaseRequirement {
  resource: 'externalUrl'
  type: Extract<RequirementType, 'view'>
}

interface ExternalToolRequirement extends BaseRequirement {
  resource: 'externalTool'
  type: Extract<RequirementType, 'view'>
}

export type Requirement =
  | AssignmentRequirement
  | QuizRequirement
  | FileRequirement
  | PageRequirement
  | DiscussionRequirement
  | ExternalUrlRequirement
  | ExternalToolRequirement
