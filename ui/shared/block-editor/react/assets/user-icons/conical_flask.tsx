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
  <path
    fillRule="evenodd"
    clipRule="evenodd"
    d="M8.93044 3.11601V13.4067L4.19616 21.8298C3.74149 22.6395 3.74466 23.6343 4.20489 24.4408C4.66513 25.2473 5.51326 25.7435 6.43055 25.7435H19.3791C20.2964 25.7435 21.1445 25.2473 21.6048 24.4408C22.065 23.6343 22.0682 22.6395 21.6135 21.8298L16.8792 13.4067V3.11601H17.6741C18.1129 3.11601 18.469 2.75397 18.469 2.30788C18.469 1.8618 18.1129 1.49976 17.6741 1.49976H8.13556C7.69679 1.49976 7.34069 1.8618 7.34069 2.30788C7.34069 2.75397 7.69679 3.11601 8.13556 3.11601H8.93044ZM18.4404 19.4418C17.5143 19.9428 15.4166 20.6677 12.5463 19.1912C10.2619 18.017 8.41933 18.6223 7.68248 18.9795C7.65943 18.99 7.63638 19.0005 7.61253 19.0086L5.57686 22.6314C5.40278 22.9409 5.40437 23.3208 5.58004 23.6295C5.75571 23.9374 6.08001 24.1273 6.43055 24.1273H19.3791C19.7296 24.1273 20.0539 23.9374 20.2296 23.6295C20.4053 23.3208 20.4069 22.9409 20.2328 22.6314L18.4404 19.4418ZM10.5202 3.11601V13.6216C10.5202 13.7679 10.482 13.9045 10.4153 14.0225L8.76033 16.9673C9.93198 16.7749 11.4947 16.8396 13.2633 17.7495C15.4349 18.8656 17.0032 18.354 17.6479 18.0316L15.3944 14.0225C15.3252 13.9004 15.2895 13.7622 15.2895 13.6216V3.11601H10.5202Z"
    fill="currentColor"
  />
</svg>`}
      size={size}
    />
  )
}
