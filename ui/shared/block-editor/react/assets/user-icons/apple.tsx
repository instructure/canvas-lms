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
      src={`<svg width="27" height="26" viewBox="0 0 27 26" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g clipPath="url(#clip0_1214_13724)">
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M12.9821 6.49083C11.4581 4.94569 9.64483 4.0406 8.08544 4.0406C6.58357 4.0406 5.17289 4.82528 4.04649 6.21768C2.52572 8.09819 1.5127 11.1254 1.5127 14.5462C1.5127 17.9985 3.14684 21.0613 5.19097 22.9596C6.63204 24.2979 8.28427 25.0518 9.72863 25.0518C11.2576 25.0518 12.6987 24.2284 13.8366 22.7859C14.9745 24.2284 16.4156 25.0518 17.9446 25.0518C19.3889 25.0518 21.0412 24.2979 22.4822 22.9596C24.5264 21.0613 26.1605 17.9985 26.1605 14.5462C26.1605 11.1254 25.1475 8.09819 23.6267 6.21768C22.5003 4.82528 21.0896 4.0406 19.5878 4.0406C18.0045 4.0406 16.1592 4.97398 14.6212 6.56195C14.6492 6.04475 14.7247 5.43704 14.8956 4.82609C15.1659 3.86281 15.6753 2.8777 16.6974 2.32414C17.095 2.10918 17.2396 1.61784 17.0211 1.2267C16.8026 0.835571 16.303 0.693341 15.9054 0.908303C14.4643 1.68814 13.692 3.03852 13.3116 4.39698C13.1054 5.13318 13.015 5.86777 12.9821 6.49083ZM13.135 9.31442C13.2845 9.55443 13.5499 9.70151 13.8366 9.70151C14.1233 9.70151 14.3887 9.55443 14.5382 9.31442C15.8865 7.14218 17.8813 5.65685 19.5878 5.65685C20.6254 5.65685 21.5629 6.26213 22.3401 7.2238C23.6752 8.87399 24.5173 11.544 24.5173 14.5462C24.5173 17.5161 23.1132 20.1514 21.355 21.7838C20.2615 22.7988 19.0398 23.4356 17.9446 23.4356C16.5963 23.4356 15.4247 22.4359 14.5497 20.9296C14.4035 20.6775 14.1316 20.5223 13.8366 20.5223C13.5416 20.5223 13.2697 20.6775 13.1235 20.9296C12.2485 22.4359 11.0769 23.4356 9.72863 23.4356C8.63345 23.4356 7.41174 22.7988 6.3182 21.7838C4.55999 20.1514 3.15588 17.5161 3.15588 14.5462C3.15588 11.544 3.99802 8.87399 5.33311 7.2238C6.11033 6.26213 7.04777 5.65685 8.08544 5.65685C9.79189 5.65685 11.7867 7.14218 13.135 9.31442Z"
      fill="currentColor"
    />
  </g>
  <defs>
    <clipPath id="clip0_1214_13724">
      <rect width="26.291" height="25.86" fill="white" transform="translate(0.691406)" />
    </clipPath>
  </defs>
</svg> `}
      size={size}
    />
  )
}
