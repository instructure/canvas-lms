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
      src={`<svg width="26" height="27" viewBox="0 0 26 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1214_13766)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9.69748 19.2738V22.5063H8.88936C8.44327 22.5063 8.08123 22.8684 8.08123 23.3145C8.08123 23.7605 8.44327 24.1226 8.88936 24.1226H16.9706C17.4167 24.1226 17.7787 23.7605 17.7787 23.3145C17.7787 22.8684 17.4167 22.5063 16.9706 22.5063H16.1625V19.2738H24.2437C24.6898 19.2738 25.0519 18.9118 25.0519 18.4657V3.91945C25.0519 3.47337 24.6898 3.11133 24.2437 3.11133H1.61623C1.17015 3.11133 0.808105 3.47337 0.808105 3.91945V18.4657C0.808105 18.9118 1.17015 19.2738 1.61623 19.2738H9.69748ZM14.5462 19.2738V22.5063H11.3137V19.2738H14.5462ZM23.4356 16.0413H2.42436V17.6576H10.5048H15.3544H15.356H23.4356V16.0413ZM2.42436 14.4251V4.72758H23.4356V14.4251H2.42436Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13766">
<rect width="25.86" height="25.86" fill="white" transform="translate(0 0.687012)"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
