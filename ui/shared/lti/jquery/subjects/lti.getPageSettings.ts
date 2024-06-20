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

import type {LtiMessageHandler} from '../lti_message_handler'

interface pageSettings {
  locale: string
  time_zone: string
  use_high_contrast: boolean
  active_brand_config_json_url: string
  window_width: number
}

const getPageSettings: LtiMessageHandler = ({responseMessages}) => {
  const pageSettings: pageSettings = {
    locale: ENV.LOCALE || '',
    time_zone: ENV.TIMEZONE || '',
    use_high_contrast: !!ENV.use_high_contrast,
    active_brand_config_json_url: ENV.active_brand_config_json_url || '',
    window_width: window.innerWidth,
  }

  responseMessages.sendResponse({pageSettings})
  return true
}

export default getPageSettings
