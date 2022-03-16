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

const BUTTON_AND_ICON_PARAM = 'icon_maker_icon'

export default function buildDownloadUrl(url) {
  let downloadUrl

  try {
    downloadUrl = new URL(url)
  } catch (e) {
    throw `Error parsing ${url}. 'buildButtonAndIconURL' only supports absolute URLs.`
  }

  downloadUrl.searchParams.append(BUTTON_AND_ICON_PARAM, 1)

  return downloadUrl.toString()
}
