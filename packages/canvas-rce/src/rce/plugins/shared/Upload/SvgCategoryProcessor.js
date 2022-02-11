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

import {BUTTONS_AND_ICONS} from '../../instructure_buttons/registerEditToolbar'

export const typeTest = 'image/svg'
const sliceSize = 400 // bytes
const buttonIconType = 'image/svg+xml-buttons-and-icons'

export async function process(file) {
  try {
    // The first slice of 400 bytes is sufficient to grab
    // the "type" metadata for button & icon SVGs
    const slice = await file.slice(0, sliceSize).text()

    if (slice.includes(buttonIconType)) {
      return {
        category: BUTTONS_AND_ICONS
      }
    }
  } catch {
    return
  }
}
