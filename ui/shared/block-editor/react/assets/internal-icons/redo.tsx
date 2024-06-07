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
<g clip-path="url(#clip0_705_45071)">
<path d="M1.40562 11.3978C1.40562 8.58948 3.53375 6.30471 6.14957 6.30471H15.2982L11.8715 9.99759L12.8673 11.0626L18 5.53131L12.8673 0L11.8715 1.06503L15.3333 4.79564H6.14957C2.7587 4.79564 0 7.75737 0 11.3978C0 15.0383 2.7587 18 6.14957 18H14.4427V16.4909H6.14957C3.53375 16.4909 1.40562 14.2062 1.40562 11.3978Z" fill="#2D3B45"/>
</g>
<defs>
<clipPath id="clip0_705_45071">
<rect width="18" height="18" fill="white" transform="matrix(-1 0 0 1 18 0)"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
