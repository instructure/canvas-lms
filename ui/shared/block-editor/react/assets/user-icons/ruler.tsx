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
    d="M25.5062 7.72793C25.8222 7.41277 25.8222 6.90041 25.5062 6.58524L20.6574 1.73649C20.3423 1.42052 19.8299 1.42052 19.5148 1.73649L1.73601 19.5152C1.42003 19.8304 1.42003 20.3428 1.73601 20.6579L6.58476 25.5067C6.89993 25.8227 7.41228 25.8227 7.72745 25.5067L25.5062 7.72793ZM22.9194 8.02937L23.7922 7.15659L20.0861 3.45053L3.45004 20.0866L7.1561 23.7926L8.04585 22.9029L6.19282 21.0499C5.87684 20.7347 5.87684 20.2224 6.19282 19.9072C6.50798 19.592 7.02034 19.592 7.33551 19.9072L9.18854 21.7602L10.3312 20.6175L9.04954 19.3358C8.73437 19.0207 8.73437 18.5083 9.04954 18.1932C9.36471 17.878 9.87706 17.878 10.1922 18.1932L11.4739 19.4748L12.6166 18.3313L10.7636 16.4791C10.4484 16.1631 10.4484 15.6516 10.7636 15.3356C11.0795 15.0205 11.5911 15.0205 11.9071 15.3356L13.7601 17.1887L14.9028 16.046L13.6211 14.7643C13.3059 14.4491 13.3059 13.9368 13.6211 13.6216C13.9363 13.3064 14.4486 13.3064 14.7638 13.6216L16.0455 14.9033L17.1882 13.7606L15.3351 11.9076C15.02 11.5916 15.02 11.08 15.3351 10.7641C15.6511 10.4489 16.1627 10.4489 16.4786 10.7641L18.3309 12.6171L19.4743 11.4744L18.1927 10.1927C17.8775 9.87755 17.8775 9.3652 18.1927 9.05003C18.5078 8.73486 19.0202 8.73486 19.3354 9.05003L20.617 10.3317L21.7767 9.17206L19.9237 7.31902C19.6085 7.00385 19.6085 6.4915 19.9237 6.17634C20.2388 5.86117 20.7512 5.86117 21.0664 6.17634L22.9194 8.02937Z"
    fill="currentColor"
  />
</svg>`}
      size={size}
    />
  )
}
