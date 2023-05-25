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

/**
 * RCE related ENV
 */
export interface EnvRce {
  /**
   * From ApplicationController#rce_js_env
   */
  RICH_CONTENT_FILES_TAB_DISABLED: boolean

  /**
   * From ApplicationController#rce_js_env
   */
  RICH_CONTENT_INST_RECORD_TAB_DISABLED: boolean

  /**
   * From Services::RichContent.env_for
   */
  JWT?: string

  /**
   * From Services::RichContent.env_for
   */
  RICH_CONTENT_CAN_UPLOAD_FILES: boolean

  /**
   * From Services::RichContent.env_for
   */
  RICH_CONTENT_CAN_EDIT_FILES: boolean

  /**
   * From Services::RichContent.service_settings
   */
  RICH_CONTENT_APP_HOST?: string

  /**
   * Maximum number of most recently used LTI tools display in the menu.
   *
   * Appears to be no longer set by the server, but is still referenced in the client code.
   */
  MAX_MRU_LTI_TOOLS?: number
}
