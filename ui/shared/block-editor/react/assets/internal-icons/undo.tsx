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
import {type IconProps} from '../iconTypes'

export default ({elementRef, size = 'small'}: IconProps) => {
  return (
    <SVGIcon
      elementRef={elementRef}
      src={`<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_705_45068)">
<path d="M16.5944 11.3978C16.5944 8.58948 14.4662 6.30471 11.8504 6.30471H2.70177L6.12849 9.99759L5.13268 11.0626L-3.90362e-07 5.53131L5.13268 0L6.12849 1.06503L2.66674 4.79564H11.8504C15.2413 4.79564 18 7.75737 18 11.3978C18 15.0383 15.2413 18 11.8504 18H3.5573V16.4909H11.8504C14.4662 16.4909 16.5944 14.2062 16.5944 11.3978Z" fill="#2D3B45"/>
</g>
<defs>
<clipPath id="clip0_705_45068">
<rect width="18" height="18" fill="white"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
