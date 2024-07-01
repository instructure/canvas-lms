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
<g clip-path="url(#clip0_1214_13763)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9.57754 5.84533V21.4486C9.57754 23.5425 11.2754 25.2403 13.3693 25.2403H13.8671C15.9609 25.2403 17.6588 23.5425 17.6588 21.4486V5.84533H17.8608C18.3069 5.84533 18.6689 5.48329 18.6689 5.03721V1.80471C18.6689 1.35862 18.3069 0.996582 17.8608 0.996582H9.37551C8.92942 0.996582 8.56738 1.35862 8.56738 1.80471V5.03721C8.56738 5.48329 8.92942 5.84533 9.37551 5.84533H9.57754ZM16.0425 5.84533H15.4219H11.1938V8.26971H12.81C13.2561 8.26971 13.6182 8.63175 13.6182 9.07783C13.6182 9.52392 13.2561 9.88596 12.81 9.88596H11.1938V11.5022H12.81C13.2561 11.5022 13.6182 11.8642 13.6182 12.3103C13.6182 12.7564 13.2561 13.1185 12.81 13.1185H11.1938V14.7347H12.81C13.2561 14.7347 13.6182 15.0967 13.6182 15.5428C13.6182 15.9889 13.2561 16.351 12.81 16.351H11.1938V17.9672H12.81C13.2561 17.9672 13.6182 18.3292 13.6182 18.7753C13.6182 19.2214 13.2561 19.5835 12.81 19.5835H11.1938V21.4486C11.1938 22.6503 12.1676 23.6241 13.3693 23.6241H13.8671C15.0687 23.6241 16.0425 22.6503 16.0425 21.4486V5.84533ZM16.8531 4.22908H17.0527V2.61283H10.1836V4.22908H16.8507H16.8531Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13763">
<rect width="25.86" height="25.86" fill="white" transform="translate(0.688477 0.188477)"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
