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

import {ICON_MAKER_ICONS, TYPE, SVG_TYPE} from '../../instructure_icon_maker/svg/constants'

export const typeTest = SVG_TYPE
const sliceSize = 400 // bytes
const iconMakerType = TYPE

export async function process(file) {
  try {
    // The first slice of 400 bytes is sufficient to grab
    // the "type" metadata for icon maker SVGs
    const slice = await file.slice(0, sliceSize).text()

    if (slice.includes(iconMakerType)) {
      return {
        category: ICON_MAKER_ICONS,
      }
    }
  } catch {}
}
