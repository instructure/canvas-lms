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

// Extend the global ENV object with conditional release properties
declare global {
    interface GlobalEnv {
        CONDITIONAL_RELEASE_SERVICE_ENABLED?: boolean
        CONDITIONAL_RELEASE_ENV?: {
            active_rules: Array<{
                trigger_assignment_id: string
                trigger_assignment_model: {
                    points_possible: number
                }
                scoring_ranges: Array<{
                    upper_bound: number
                    lower_bound: number
                    assignment_sets: Array<{
                        assignment_set_associations: Array<{
                            assignment_id: string
                        }>
                    }>
                }>
            }>
        }
    }
}

export type ModuleContent = {
  id?: string
  _id?: string
  title: string
  type?: string
  pointsPossible?: number
  published?: boolean
  canUnpublish?: boolean
  dueAt?: string
  lockAt?: string
  unlockAt?: string
  todoDate?: string
  url?: string
  // Assignment specific
  assignmentGroupId?: string
  submissionTypes?: string[]
  // Discussion specific
  discussionType?: string
  // File specific
  displayName?: string
  contentType?: string
  size?: string
  thumbnailUrl?: string
  // External URL specific
  externalUrl?: string
} | null

export interface CompletionRequirement {
  id: string
  type: string
  minScore?: number
  minPercentage?: number
  completed?: boolean
  fulfillmentStatus?: string
}

export interface Prerequisite {
  id: string
  type: string
  name: string
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
  unlockAt: string | null
  moduleItems: ModuleItem[]
}

export interface ModulesResponse {
  modules: Module[]
  pageInfo: {
    hasNextPage: boolean
    endCursor: string | null
  }
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
  content: {
    title: string
    type?: string
    pointsPossible?: number
    published?: boolean
    canUnpublish?: boolean
    id?: string
  } | null
}

interface ModuleItemContent {
  id?: string
  _id?: string
  title?: string
  type?: string
  pointsPossible?: number
  published?: boolean
  canUnpublish?: boolean
}
