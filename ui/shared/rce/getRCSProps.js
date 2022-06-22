/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {refreshFn as refreshToken} from './jwt'
import splitAssetString from '@canvas/util/splitAssetString'

export default function getRCSProps() {
  if (!ENV.context_asset_string) {
    return null
  }
  let [contextType, contextId] = splitAssetString(ENV.context_asset_string, false)
  const userId = ENV.current_user_id
  const containingContext = {contextType, contextId, userId}

  if (contextType === 'account') {
    contextId = userId
    contextType = 'user'
  }

  return {
    containingContext, // this will remain constant
    contextType, // these will change via the UI
    contextId,
    filesTabDisabled: ENV.RICH_CONTENT_FILES_TAB_DISABLED,
    host: ENV.RICH_CONTENT_APP_HOST,
    jwt: ENV.JWT,
    refreshToken: refreshToken(ENV.JWT),
    themeUrl: ENV.active_brand_config_json_url,
    canvasUrl: ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN,
    features: {
      // This feature was re-named to match the updated name "Buttons and Icons" => "Icon Maker"
      // But the feature flag was NOT renamed so it's still "buttons_and_icons_cropper"
      icon_maker_cropper: ENV.FEATURES?.buttons_and_icons_cropper
    }
  }
}
