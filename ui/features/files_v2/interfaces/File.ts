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

export interface UsageRights {
  use_justification: string
  license: string
  legal_copyright: string
  license_name: string
}
export interface User {
  id: string
  anonymous_id: string
  display_name: string
  avatar_image_url: string
  html_url: string
  pronouns: string | null
}

export interface File {
  id: number
  folder_id: string
  display_name: string
  filename: string
  upload_status: string
  'content-type': string
  url: string
  size: number
  created_at: string
  updated_at: string
  unlock_at: string | null
  locked: boolean
  hidden: boolean
  lock_at: string | null
  hidden_for_user: boolean
  thumbnail_url: string | null
  modified_at: string
  mime_class: string
  media_entry_id: string | null
  category: string
  locked_for_user: boolean
  visibility_level: string
  user?: User
  usage_rights?: UsageRights | null
  preview_url: string
  context_asset_string: string
  restricted_by_master_course?: boolean
  [key: string]: any
}

export interface Folder {
  id: number
  name: string
  full_name: string
  context_id: string
  context_type: string
  parent_folder_id: string | null
  created_at: string
  updated_at: string
  lock_at: string | null
  unlock_at: string | null
  position: number
  locked: boolean
  folders_url: string
  files_url: string
  files_count: number
  folders_count: number
  hidden: boolean | null
  locked_for_user: boolean
  hidden_for_user: boolean
  for_submissions: boolean
  can_upload: boolean
  [key: string]: any
}
