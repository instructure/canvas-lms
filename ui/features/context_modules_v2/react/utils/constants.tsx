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
import persistedQueries from '@canvas/graphql/persistedQueries'
import {ModuleItemContentType} from '../hooks/queries/useModuleItemContent'

export const SHOW_ALL_PAGE_SIZE = 100

// Backward compatibility - these will be deprecated
export const PAGE_SIZE = ENV.MODULE_FEATURES?.PAGE_SIZE || 10
export const MODULES_ARE_PAGINATED = !!ENV.MODULE_FEATURES?.MODULES_ARE_PAGINATED

export const STUDENT = 'student'
export const TEACHER = 'teacher'
export const MODULE_ITEMS = 'moduleItems'
export const MODULE_ITEMS_ALL = 'moduleItemsAll'
export const MODULE_ITEMS_STUDENT = 'moduleItemsStudent'
export const MODULE_ITEM_TITLES = 'moduleItemTitles'
export const MODULES = 'modules'
export const MODULE_ITEMS_QUERY_MAP: Record<string, string> = {
  [TEACHER]: persistedQueries.GetModuleItemsQuery.query,
  [STUDENT]: persistedQueries.GetModuleItemsStudentQuery.query,
  [MODULE_ITEM_TITLES]: persistedQueries.GetModuleItemTitlesQuery.query,
}
export const MODULES_QUERY_MAP: Record<string, string> = {
  [TEACHER]: persistedQueries.GetModulesQuery.query,
  [STUDENT]: persistedQueries.GetModulesStudentQuery.query,
}
export const MODULE_ITEMS_MAP: Record<string, string> = {
  [TEACHER]: MODULE_ITEMS,
  [STUDENT]: MODULE_ITEMS_STUDENT,
}
export const MOVE_MODULE_ITEM = 'move_module_item' as const
export const MOVE_MODULE_CONTENTS = 'move_module_contents' as const
export const MOVE_MODULE = 'move_module' as const

export const ITEM_TYPE = {
  ASSIGNMENT: 'assignment',
  QUIZ: 'quiz',
  FILE: 'file',
  PAGE: 'page',
  DISCUSSION: 'discussion',
  CONTEXT_MODULE_SUB_HEADER: 'context_module_sub_header',
  EXTERNAL_URL: 'external_url',
  EXTERNAL_TOOL: 'external_tool',
} as const

export type ItemType = (typeof ITEM_TYPE)[keyof typeof ITEM_TYPE]

export const TYPES_WITH_CREATE_NAME: readonly ItemType[] = [
  ITEM_TYPE.ASSIGNMENT,
  ITEM_TYPE.QUIZ,
  ITEM_TYPE.PAGE,
  ITEM_TYPE.DISCUSSION,
] as const

export const TYPES_WITH_URL: readonly ItemType[] = [ITEM_TYPE.EXTERNAL_URL, ITEM_TYPE.EXTERNAL_TOOL]

export const TYPES_WITH_TABS: ModuleItemContentType[] = [
  ITEM_TYPE.ASSIGNMENT,
  ITEM_TYPE.QUIZ,
  ITEM_TYPE.FILE,
  ITEM_TYPE.PAGE,
  ITEM_TYPE.DISCUSSION,
]
export const NAMELESS_TYPES = ['file', 'context_module_sub_header', 'external_url', 'external_tool']
export const NEW_ITEM_FIELDS = ['name', 'assignmentGroup', 'file', 'folder'] as const

const BASE_EXTERNAL_FIELDS = ['url', 'name', 'newTab', 'isUrlValid'] as const
export const EXTERNAL_NEW_ITEM_FIELDS = BASE_EXTERNAL_FIELDS
export const EXTERNAL_TOOL_NEW_ITEM_FIELDS = [...BASE_EXTERNAL_FIELDS, 'selectedToolId'] as const
