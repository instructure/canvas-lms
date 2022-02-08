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

export enum Feature {
  ButtonsAndIcons
}

export default function shouldUseFeature(feature: Feature, windowEnv: object): boolean {
  switch (feature) {
    case Feature.ButtonsAndIcons:
      return shouldUseButtonsAndIcons(windowEnv)
    default:
      return false
  }
}

function shouldUseButtonsAndIcons(windowEnv: object): boolean {
  return !!(
    windowEnv.RICH_CONTENT_CAN_UPLOAD_FILES &&
    windowEnv.RICH_CONTENT_CAN_EDIT_FILES &&
    window.ENV?.FEATURES?.buttons_and_icons_root_account
  )
}
