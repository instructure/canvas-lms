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

import {type Folder} from '../interfaces/File'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'

export const generateUrlPath = (folder: Folder) => {
  const EVERYTHING_BEFORE_THE_FIRST_SLASH = /^[^\/]+\/?/

  const getRelativePath = (fullName: string) => {
    return fullName
      .replace(EVERYTHING_BEFORE_THE_FIRST_SLASH, '')
      .replace(/%/g, '&#37;')
      .split('/')
      .map(encodeURIComponent)
      .join('/')
  }

  let relativePath = getRelativePath(folder.full_name)
  if (filesEnv.showingAllContexts) {
    const pluralAssetString = folder.context_type
      ? `${folder.context_type.toLowerCase()}s_${folder.context_id}`
      : ''
    relativePath = pluralAssetString ? `${pluralAssetString}/${relativePath}` : relativePath
  }
  return `/folder/${relativePath}`
}

// The root folder only needs to have context info for use in breadcrumbs
export const createStubRootFolder = (
  context_id: string,
  plural_context_type: string,
  root_folder_id: string,
): Folder => {
  return {
    id: root_folder_id,
    name: '',
    parent_folder_id: null,
    context_id: context_id,
    context_type: plural_context_type.toLowerCase().slice(0, -1),
    hidden: false,
    full_name: '',
    created_at: '',
    updated_at: '',
    lock_at: '',
    unlock_at: '',
    position: 0,
    locked: false,
    locked_for_user: false,
    folders_count: 0,
    files_count: 0,
    folders_url: '',
    files_url: '',
    hidden_for_user: false,
    locked_by: null,
    can_upload: false,
    for_submissions: false,
  }
}
