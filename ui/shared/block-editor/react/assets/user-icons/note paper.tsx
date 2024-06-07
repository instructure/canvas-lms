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
      src={`<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path
    fillRule="evenodd"
    clipRule="evenodd"
    d="M17.9446 3.11137H14.6583V2.30324C14.6583 1.85716 14.2902 1.49512 13.8367 1.49512C13.3831 1.49512 13.0151 1.85716 13.0151 2.30324V3.11137H9.72869V2.30324C9.72869 1.85716 9.36062 1.49512 8.9071 1.49512C8.45358 1.49512 8.08551 1.85716 8.08551 2.30324V3.11137H4.79913C4.34561 3.11137 3.97754 3.47341 3.97754 3.91949V24.9307C3.97754 25.3768 4.34561 25.7389 4.79913 25.7389H22.8742C23.3277 25.7389 23.6958 25.3768 23.6958 24.9307V3.91949C23.6958 3.47341 23.3277 3.11137 22.8742 3.11137H19.5878V2.30324C19.5878 1.85716 19.2197 1.49512 18.7662 1.49512C18.3127 1.49512 17.9446 1.85716 17.9446 2.30324V3.11137ZM19.5878 4.72762V5.13168C19.5878 5.57777 19.2197 5.93981 18.7662 5.93981C18.3127 5.93981 17.9446 5.57777 17.9446 5.13168V4.72762H14.6583V5.13168C14.6583 5.57777 14.2902 5.93981 13.8367 5.93981C13.3831 5.93981 13.0151 5.57777 13.0151 5.13168V4.72762H9.72869V5.13168C9.72869 5.57777 9.36062 5.93981 8.9071 5.93981C8.45358 5.93981 8.08551 5.57777 8.08551 5.13168V4.72762H5.62073V24.1226H22.0526V4.72762H19.5878Z"
    fill="currentColor"
  />
</svg>`}
      size={size}
    />
  )
}
