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

export type MediaInfo = {
  auto_caption_status: any
  can_add_captions: boolean
  created_at: string
  embedded_iframe_url: string
  media_id: string
  media_sources: any[]
  media_tracks: MediaTrack[]
  media_type: string
  status?:
    | 'ERROR_IMPORTING'
    | 'ERROR_CONVERTING'
    | 'SCAN_FAILURE'
    | 'IMPORT'
    | 'INFECTED'
    | 'PRECONVERT'
    | 'READY'
    | 'DELETED'
    | 'PENDING'
    | 'MODERATE'
    | 'BLOCKED'
    | 'NO_CONTENT'
  title: string
}

export type MediaTrack = {
  asr: boolean
  created_at: string
  id: string
  inherited: boolean
  kind: string
  locale: string
  updated_at: string
  url: string
  workflow_state: 'ready' | 'failed' | 'processing'
}
