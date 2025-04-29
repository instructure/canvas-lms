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

import {FileContext, Permissions} from '@canvas/files_v2/react/modules/filesEnvFactory.types'

const tools = [
  {
    id: 'tool1',
    title: 'Test Tool',
    base_url: 'http://example.com/tool1',
    icon_url: 'http://example.com/tool1/icon.png',
  },
]

export const MULITPLE_CONTEXTS: FileContext[] = [
  {
    contextType: 'users',
    contextId: '1',
    root_folder_id: '2',
    asset_string: 'user_1',
    permissions: {},
    name: 'My Files',
    file_menu_tools: tools,
    file_index_menu_tools: tools,
  },
  {
    contextType: 'courses',
    contextId: '2',
    root_folder_id: '1',
    asset_string: 'course_2',
    permissions: {},
    name: 'Course 1',
    file_menu_tools: tools,
    file_index_menu_tools: tools,
  },
]

export const SINGLE_CONTEXT: FileContext[] = [
  {
    contextType: 'courses',
    contextId: '2',
    root_folder_id: '1',
    asset_string: 'course_2',
    permissions: {},
    name: 'Course 1',
    file_menu_tools: tools,
    file_index_menu_tools: tools,
  },
]

interface FileContextOptions {
  permissions?: Permissions
  hasNoTools?: boolean
  isMultipleContexts?: boolean
  usageRightsRequired?: boolean
}

export const createFilesContexts = (options?: FileContextOptions): FileContext[] => {
  const contexts = options?.isMultipleContexts ? MULITPLE_CONTEXTS : SINGLE_CONTEXT
  if (options?.hasNoTools) {
    contexts.forEach(context => {
      context.file_menu_tools = []
      context.file_index_menu_tools = []
    })
  }

  if (options?.permissions) {
    contexts.forEach(context => {
      context.permissions = options.permissions!
    })
  }

  if (options?.usageRightsRequired) {
    contexts.forEach(context => {
      context.usage_rights_required = options.usageRightsRequired
    })
  }

  return contexts
}
