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
  let {width, height} = elem.getBoundingClientRect()
  if (to === 'percent') {
    const parent = elem.offsetParent
    if (parent) {
      width = percentSize(parent.clientWidth, width)
    }
  }
  return {width, height}
}

const percentSize = (parentWidth: number, width: number) => {
  let w = width

  if (parentWidth - width <= 7) {
    w = parentWidth
  }
  return (w / parentWidth) * 100
}

export {changeSizeVariant, percentSize}
