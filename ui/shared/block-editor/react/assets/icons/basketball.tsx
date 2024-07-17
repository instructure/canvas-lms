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
<g clip-path="url(#clip0_1214_13748)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M22.0725 21.6102C22.0806 21.603 22.0887 21.5949 22.096 21.5868C24.231 19.4008 25.5475 16.4124 25.5475 13.1185C25.5475 9.82454 24.231 6.83609 22.096 4.65011C22.0887 4.64203 22.0806 4.63396 22.0725 4.62668V4.62587C21.86 4.4101 21.6394 4.2016 21.4115 4.00199C20.9735 3.61733 20.5072 3.26499 20.0183 2.9474C19.0291 2.30413 17.947 1.80713 16.8141 1.47742C16.149 1.28347 15.4669 1.1477 14.7784 1.07174C14.3291 1.02164 13.8773 0.996582 13.4256 0.996582C10.0412 0.996582 6.97836 2.38656 4.77865 4.62668C4.77057 4.63396 4.76249 4.64203 4.75521 4.65011C2.62015 6.83609 1.30371 9.82454 1.30371 13.1185C1.30371 16.4124 2.62015 19.4008 4.75521 21.5868C4.76249 21.5949 4.77057 21.603 4.77865 21.6102C6.97836 23.8504 10.0412 25.2403 13.4256 25.2403C16.81 25.2403 19.8728 23.8504 22.0725 21.6102ZM12.6175 23.5934V13.9266H9.35829C9.18131 16.616 8.1251 19.0663 6.47571 20.9936C8.13883 22.4636 10.2707 23.4148 12.6175 23.5934ZM17.4929 13.9266H14.2337V23.5934C16.5797 23.4148 18.7115 22.4636 20.3755 20.9936C18.7261 19.0663 17.6699 16.616 17.4929 13.9266ZM5.34434 6.4086C3.83072 8.22931 2.91996 10.568 2.91996 13.1185C2.91996 15.6689 3.83072 18.0076 5.34434 19.8283C6.85795 18.0084 7.76871 15.6689 7.76871 13.1185C7.76871 10.568 6.85795 8.2285 5.34434 6.4086ZM21.5068 6.4086C19.9932 8.2285 19.0825 10.568 19.0825 13.1185C19.0825 15.6689 19.9932 18.0084 21.5068 19.8283C23.0205 18.0076 23.9312 15.6689 23.9312 13.1185C23.9312 10.568 23.0205 8.22931 21.5068 6.4086ZM12.6175 2.64354C10.2715 2.82213 8.13964 3.7733 6.47571 5.24328C8.1251 7.17066 9.18131 9.62089 9.35829 12.3103H12.6175V2.64354ZM14.2337 2.64354V12.3103H17.4929C17.6699 9.62089 18.7261 7.17066 20.3755 5.24328C18.7123 3.7733 16.5805 2.82213 14.2337 2.64354Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13748">
<rect width="25.86" height="25.86" fill="white" transform="translate(0.495117 0.188477)"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
