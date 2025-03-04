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

import filesEnv from '@canvas/files_v2/react/modules/filesEnv'

const fileIndexMenuTools = [
  {
    id: 'tool1',
    title: 'Test Tool',
    base_url: 'http://example.com/tool1',
    icon_url: 'http://example.com/tool1/icon.png',
  },
]

const setupFilesEnvWithAllContexts = () => {
  filesEnv.showingAllContexts = true
  filesEnv.contexts = [
    {
      contextType: 'users',
      contextId: '1',
      root_folder_id: '2',
      asset_string: 'user_1',
      permissions: {},
      name: 'My Files',
      file_index_menu_tools: fileIndexMenuTools,
    },
    {
      contextType: 'courses',
      contextId: '1',
      root_folder_id: '1',
      asset_string: 'course_1',
      permissions: {},
      name: 'Course 1',
      file_index_menu_tools: fileIndexMenuTools,
    },
  ]
  filesEnv.contextsDictionary = {
    users_1: filesEnv.contexts[0],
    courses_1: filesEnv.contexts[1],
  }
}

const setupFilesEnvWithSingleContext = () => {
  filesEnv.showingAllContexts = false
  filesEnv.contexts = [
    {
      contextType: 'courses',
      contextId: '1',
      root_folder_id: '1',
      asset_string: 'course_1',
      permissions: {},
      name: 'Course 1',
      file_index_menu_tools: fileIndexMenuTools,
    },
  ]
  filesEnv.contextsDictionary = {
    courses_1: filesEnv.contexts[0],
  }
}

export const setupFilesEnv = (showingAllContexts = false) => {
  if (showingAllContexts) {
    setupFilesEnvWithAllContexts()
  } else {
    setupFilesEnvWithSingleContext()
  }
}
