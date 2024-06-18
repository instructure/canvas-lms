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
      src={`<svg width="26" height="27" viewBox="0 0 26 27" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g clipPath="url(#clip0_1214_13757)">
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M2.31774 18.7071L2.30582 18.7192C2.20646 18.8243 2.14128 18.9496 2.10869 19.0821L2.10472 19.0999L2.10313 19.1055C2.09915 19.1249 2.09597 19.1443 2.09279 19.1645L1.29791 24.8214C1.26294 25.0727 1.34561 25.3273 1.52287 25.5067C1.69933 25.6869 1.94971 25.7709 2.19692 25.7354L7.76106 24.9273C7.78093 24.924 7.80001 24.9208 7.81909 24.9168L7.84214 24.9111C7.9725 24.878 8.09571 24.8117 8.19904 24.7107L8.21096 24.6986L24.9034 7.72793C25.2142 7.41277 25.2142 6.90041 24.9034 6.58524L20.1341 1.73649C19.8241 1.42052 19.3202 1.42052 19.0102 1.73649L2.31774 18.7071ZM3.02201 23.9826L5.96305 23.5559L3.4417 20.9925L3.02201 23.9826ZM6.38354 21.698L7.64898 22.9845L20.8328 9.58096L19.5674 8.29443L6.38354 21.698ZM4.00368 19.2785L5.25958 20.5553L18.4434 7.15174L17.1875 5.8749L4.00368 19.2785ZM18.3115 4.73221L20.0554 6.50443C20.0825 6.52625 20.1087 6.54969 20.1341 6.57555C20.1596 6.6006 20.1826 6.62807 20.2033 6.65555L21.9568 8.43827L23.2174 7.15659L19.5721 3.45053L18.3115 4.73221Z"
      fill="currentColor"
    />
  </g>
  <defs>
    <clipPath id="clip0_1214_13757">
      <rect width="25.4361" height="25.86" fill="white" transform="translate(0.495117 0.69165)" />
    </clipPath>
  </defs>
</svg>`}
      size={size}
    />
  )
}
