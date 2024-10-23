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

import {type SizeVariant, type Sz} from '../components/editor/types'

const changeSizeVariant = (elem: HTMLElement, to: SizeVariant): Sz => {
  const {width, height} = elem.getBoundingClientRect()
  if (to === 'percent') {
    const parent = elem.offsetParent
    if (parent) {
      return percentSize(parent.clientWidth, parent.clientHeight, width, height)
    }
  }
  return {width, height}
}

const percentSize = (parentWidth: number, parentHeight: number, width: number, height: number) => {
  let w = width,
    h = height
  if (parentWidth - width <= 7) {
    w = parentWidth
  }
  if (parentHeight - height <= 7) {
    h = parentHeight
  }
  return {
    width: (w / parentWidth) * 100,
    height: (h / parentHeight) * 100,
  }
}

export {changeSizeVariant, percentSize}
