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

export interface Permissions {
  manage_files_add?: boolean
  manage_files_edit?: boolean
  manage_files_boolean?: boolean
  [key: string]: boolean | undefined
}

export interface Tool {
  id: string
  title: string
  base_url: string
  canvas_icon_class?: string
  icon_url: string
  accept_media_types?: string
}

export interface FileContext {
  asset_string: string
  contextType: string
  contextId: string
  root_folder_id: string
  permissions: Permissions
  name: string
  usage_rights_required?: boolean
  file_index_menu_tools?: Tool[]
  file_menu_tools?: Tool[]
}

export interface FilesEnv {
  showingAllContexts: boolean
  contexts: FileContext[]
  contextsDictionary: Record<string, FileContext>
  contextType: string
  contextId: string
  baseUrl: string
  contextFor(folder: {contextType: string; contextId: string}): FileContext | undefined
  userHasPermission(folder: {contextType: string; contextId: string}, action: string): boolean
}
