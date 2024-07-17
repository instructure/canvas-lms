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

import React from 'react'
import {SVGIcon} from '@instructure/ui-svg-images'
import {type IconProps} from './iconTypes'

export default ({elementRef, size = 'small'}: IconProps) => {
  return (
    <SVGIcon
      elementRef={elementRef}
      src={`<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M19.0825 2.92288H14.2337V2.51882C14.2337 2.07273 13.8717 1.71069 13.4256 1.71069C12.9795 1.71069 12.6175 2.07273 12.6175 2.51882V2.92288H7.76871V2.51882C7.76871 2.07273 7.40667 1.71069 6.96059 1.71069C6.5145 1.71069 6.15246 2.07273 6.15246 2.51882V2.92288H2.11184C1.66575 2.92288 1.30371 3.28492 1.30371 3.73101V23.126C1.30371 23.5721 1.66575 23.9341 2.11184 23.9341H24.7393C25.1854 23.9341 25.5475 23.5721 25.5475 23.126V3.73101C25.5475 3.28492 25.1854 2.92288 24.7393 2.92288H20.6987V2.51882C20.6987 2.07273 20.3367 1.71069 19.8906 1.71069C19.4445 1.71069 19.0825 2.07273 19.0825 2.51882V2.92288ZM23.9312 9.38788V22.3179H2.91996V9.38788H23.9312ZM2.91996 7.77163H23.9312V4.53913H20.6987V5.34726C20.6987 5.79334 20.3367 6.15538 19.8906 6.15538C19.4445 6.15538 19.0825 5.79334 19.0825 5.34726V4.53913H14.2337V5.34726C14.2337 5.79334 13.8717 6.15538 13.4256 6.15538C12.9795 6.15538 12.6175 5.79334 12.6175 5.34726V4.53913H7.76871V5.34726C7.76871 5.79334 7.40667 6.15538 6.96059 6.15538C6.5145 6.15538 6.15246 5.79334 6.15246 5.34726V4.53913H2.91996V7.77163Z" fill="black"/>
</svg>`}
      size={size}
    />
  )
}
