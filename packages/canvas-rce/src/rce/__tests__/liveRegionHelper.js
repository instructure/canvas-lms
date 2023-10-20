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

export const LIVE_REGION_ID = 'flash_screenreader_holder'

const getLiveRegion = () => document.getElementById(LIVE_REGION_ID)

export const createLiveRegion = () => {
  if (!getLiveRegion()) {
    const liveRegion = document.createElement('div')
    liveRegion.id = LIVE_REGION_ID
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
}

export const removeLiveRegion = () => {
  if (getLiveRegion()) {
    document.body.removeChild(getLiveRegion())
  }
}
