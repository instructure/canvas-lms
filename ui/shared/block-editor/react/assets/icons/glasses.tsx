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
<g clip-path="url(#clip0_1214_13754)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M4.88152 17.1591C5.26274 19.0024 6.92154 20.3916 8.90733 20.3916C10.8931 20.3916 12.5519 19.0024 12.9331 17.1591H14.7406C15.1219 19.0024 16.7807 20.3916 18.7665 20.3916C20.7522 20.3916 22.411 19.0024 22.7923 17.1591H23.696C24.0879 17.1591 24.4248 16.8876 24.502 16.5093L26.1452 8.4281C26.2175 8.07091 26.0384 7.70968 25.7065 7.54725L22.4201 5.931C22.015 5.73139 21.5204 5.89301 21.3183 6.29222C21.1154 6.69063 21.2797 7.17712 21.6856 7.37592L24.4108 8.7166L23.0223 15.5428H22.7923C22.411 13.6995 20.7522 12.3103 18.7665 12.3103C16.7807 12.3103 15.1219 13.6995 14.7406 15.5428H12.9331C12.5519 13.6995 10.8931 12.3103 8.90733 12.3103C6.92154 12.3103 5.26274 13.6995 4.88152 15.5428H4.65148L3.26298 8.7166L5.98821 7.37592C6.39407 7.17712 6.55839 6.69063 6.35546 6.29222C6.15335 5.89301 5.65875 5.73139 5.2537 5.931L1.96733 7.54725C1.63541 7.70968 1.4563 8.07091 1.5286 8.4281L3.17178 16.5093C3.24901 16.8876 3.58587 17.1591 3.97777 17.1591H4.88152ZM8.90733 13.9266C10.2679 13.9266 11.3721 15.0127 11.3721 16.351C11.3721 17.6892 10.2679 18.7753 8.90733 18.7753C7.54677 18.7753 6.44255 17.6892 6.44255 16.351C6.44255 15.0127 7.54677 13.9266 8.90733 13.9266ZM18.7665 13.9266C20.127 13.9266 21.2312 15.0127 21.2312 16.351C21.2312 17.6892 20.127 18.7753 18.7665 18.7753C17.4059 18.7753 16.3017 17.6892 16.3017 16.351C16.3017 15.0127 17.4059 13.9266 18.7665 13.9266Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13754">
<rect width="26.291" height="25.86" fill="white" transform="translate(0.691406 0.188477)"/>
</clipPath>
</defs>
</svg>`}
      size={size}
    />
  )
}
