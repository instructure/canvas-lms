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

export interface ContextFile {
  id: string
  display_name: string
  url: string
  size: number
  content_type: string
  created_at?: string
}

export interface CanvasFolder {
  id: string
  name: string
  parent_folder_id?: string
  full_name?: string
  subFolderIDs: string[]
  subFileIDs: string[]
  created_at?: string
  locked?: boolean
}

export interface CanvasFile {
  id: string
  display_name: string
  filename: string
  folder_id: string
  created_at: string
  updated_at?: string
  user?: {
    display_name: string
  }
  size?: number
  locked: boolean
}

export interface ColumnWidths {
  thumbnailWidth: string
  nameWidth: string
  nameAndThumbnailWidth: string
  dateCreatedWidth: string
  dateModifiedWidth: string
  modifiedByWidth: string
  fileSizeWidth: string
  publishedWidth: string
}
