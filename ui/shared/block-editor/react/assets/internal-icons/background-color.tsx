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
<g clip-path="url(#clip0_13_7929)">
<path d="M5.52715 0L4.48118 1.01914L5.82475 2.33149L0.672221 7.36027C-0.224074 8.23479 -0.224074 9.6186 0.672221 10.4931L0.74662 10.5671L5.45129 15.1575C6.34759 16.032 7.7673 16.032 8.6636 15.1575L14.3398 9.61917L14.8636 9.1096L7.61763 2.0397L7.02097 1.45754L6.87072 1.31093L5.52715 0ZM6.87072 3.35205L12.7716 9.1096L11.129 10.7123H2.9859L1.71673 9.47398C1.41797 9.18248 1.41797 8.67234 1.71673 8.38083L6.87072 3.35205ZM15.7593 11.6603L15.1611 12.5342C15.1611 12.5342 14.788 13.1167 14.3398 13.7726C14.1158 14.137 13.967 14.4288 13.8176 14.7931C13.6682 15.1575 13.5185 15.3764 13.5185 15.8137C13.5185 16.9797 14.5642 18 15.7593 18C16.9543 18 18 16.9797 18 15.8137C18 15.3764 17.8503 15.0849 17.7009 14.7205C17.5516 14.3562 17.3281 13.9915 17.1787 13.7C16.8052 13.0441 16.3574 12.4616 16.3574 12.4616L15.7593 11.6603Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_13_7929">
<rect width="18" height="18" fill="white"/>
</clipPath>
</defs>
</svg>

`}
      size={size}
    />
  )
}
