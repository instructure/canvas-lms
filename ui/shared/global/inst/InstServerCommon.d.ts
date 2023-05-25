/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export type InstServerCommon = InstServerCommonBasic & InstServerCommonKaltura

/**
 * Common properties in INST from ApplicationHelper#inst_env.
 *
 * NOTE: These are all possibly undefined because falsey values are removed in ruby.
 */
export type InstServerCommonBasic = {
  environment?: string
  equellaEnabled?: boolean
  disableGooglePreviews?: boolean
  logPageViews?: boolean
  editorButtons?: EditorToolInfo[]
  pandaPubSettings?: Partial<{
    application_id: unknown
    push_url: string
    // May not be complete
  }>
}

/**
 * Kaltura-specific properties in INST from ApplicationHelper#inst_env.
 *
 * NOTE: These are all possibly undefined because falsey values are removed in ruby.
 */
export type InstServerCommonKaltura = {
  allowMediaComments?: boolean
  kalturaSettings?: {
    domain: string
    resource_domain: string
    rtmp_domain: string
    partner_id: number
    subpartner_id: number
    player_ui_conf: number
    kcw_ui_conf: number
    upload_ui_conf: number
    max_file_size_bytes: number
    js_uploader: 'yes' | unknown
    hide_rte_button?: boolean
  }
}

export interface EditorToolInfo {
  // id of the tool
  id: string | number

  // is this a favorite tool?
  favorite?: boolean

  name?: string
  description?: string
  icon_url?: string
  height?: number
  width?: number
  use_tray?: boolean
  canvas_icon_class?: string
}
