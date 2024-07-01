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
<g clip-path="url(#clip0_1214_13736)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M13.117 1.30664C6.42653 1.30664 0.995117 6.73805 0.995117 13.4285C0.995117 20.119 6.42653 25.5504 13.117 25.5504C19.8075 25.5504 25.2389 20.119 25.2389 13.4285C25.2389 6.73805 19.8075 1.30664 13.117 1.30664ZM13.117 2.92289C18.9153 2.92289 23.6226 7.63022 23.6226 13.4285C23.6226 19.2268 18.9153 23.9341 13.117 23.9341C7.3187 23.9341 2.61137 19.2268 2.61137 13.4285C2.61137 7.63022 7.3187 2.92289 13.117 2.92289ZM13.117 3.73102C7.76478 3.73102 3.41949 8.0763 3.41949 13.4285C3.41949 18.7807 7.76478 23.126 13.117 23.126C18.4692 23.126 22.8145 18.7807 22.8145 13.4285C22.8145 8.0763 18.4692 3.73102 13.117 3.73102ZM12.3089 5.38686C8.49371 5.76668 5.45516 8.80523 5.07534 12.6204H6.65199C7.09808 12.6204 7.46012 12.9824 7.46012 13.4285C7.46012 13.8746 7.09808 14.2366 6.65199 14.2366H5.07534C5.45516 18.0518 8.49371 21.0903 12.3089 21.4702V19.8935C12.3089 19.4474 12.6709 19.0854 13.117 19.0854C13.5631 19.0854 13.9251 19.4474 13.9251 19.8935V21.4702C17.7403 21.0903 20.7788 18.0518 21.1586 14.2366H19.582C19.1359 14.2366 18.7739 13.8746 18.7739 13.4285C18.7739 12.9824 19.1359 12.6204 19.582 12.6204H21.1586C20.7788 8.80523 17.7403 5.76668 13.9251 5.38686V6.96352C13.9251 7.4096 13.5631 7.77164 13.117 7.77164C12.6709 7.77164 12.3089 7.4096 12.3089 6.96352V5.38686ZM8.57129 10.8272L12.6119 14.0597C12.9335 14.3166 13.3974 14.2908 13.6883 13.9999L16.1515 11.5367C16.4667 11.2215 16.4667 10.7092 16.1515 10.394C15.8363 10.0788 15.324 10.0788 15.0088 10.394L13.0572 12.3456L9.58145 9.56487C9.23314 9.28607 8.72402 9.34264 8.44522 9.69094C8.16641 10.0392 8.22299 10.5484 8.57129 10.8272Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13736">
<rect width="25.86" height="25.86" fill="white" transform="translate(0.186523 0.498535)"/>
</clipPath>
</defs>
</svg>`}
      size={size}
    />
  )
}
