/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export type ContentShareType =
  | 'assignment'
  | 'attachment'
  | 'discussion_topic'
  | 'page'
  | 'quiz'
  | 'module'
  | 'module_item'

export type ContentExportWorkflowState = 'created' | 'exporting' | 'exported' | 'failed' | 'deleted'

export type ReadState = 'read' | 'unread'

export interface Attachment {
  id: string
  display_name: string
  url: string
}

export interface ContentExport {
  id: string
  progress_url?: string
  user_id?: string
  workflow_state: ContentExportWorkflowState
  attachment?: Attachment
  created_at?: string
}

export interface DisplayUser {
  id: string
  display_name: string
  avatar_image_url?: string
}

export interface ContentShare {
  id: string
  name: string
  content_type: ContentShareType
  created_at: string
  updated_at: string
  read_state: ReadState
  sender?: DisplayUser
  content_export?: ContentExport
}
