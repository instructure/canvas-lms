// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

export enum Feature {
  IconMaker,
}

export default function shouldUseFeature(feature: Feature, windowEnv: GlobalEnv): boolean {
  switch (feature) {
    case Feature.IconMaker:
      return shouldUseIconMaker(windowEnv)
    default:
      return false
  }
}

function shouldUseIconMaker(windowEnv: GlobalEnv): boolean {
  return !!(
    windowEnv.RICH_CONTENT_CAN_UPLOAD_FILES &&
    windowEnv.RICH_CONTENT_CAN_EDIT_FILES &&
    // This feature was re-named to match the updated name: "Buttons and Icons" => "Icon Maker"
    // But the feature flag was NOT renamed so it's still "buttons_and_icons_root_account"
    window.ENV?.FEATURES?.buttons_and_icons_root_account
  )
}
