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
<g clip-path="url(#clip0_1214_13739)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M9.69736 2.61283V11.4513C7.3037 12.6417 5.65674 15.1137 5.65674 17.9672C5.65674 21.9812 8.91591 25.2403 12.9299 25.2403C16.9438 25.2403 20.203 21.9812 20.203 17.9672C20.203 15.1137 18.556 12.6417 16.1624 11.4513V2.61283H16.9705C17.4166 2.61283 17.7786 2.25079 17.7786 1.80471C17.7786 1.35862 17.4166 0.996582 16.9705 0.996582H8.88924C8.44315 0.996582 8.08111 1.35862 8.08111 1.80471C8.08111 2.25079 8.44315 2.61283 8.88924 2.61283H9.69736ZM18.4639 19.1454C17.3212 19.5883 15.2678 19.9641 12.5848 18.6978C10.1483 17.5478 8.16597 18.0787 7.29319 18.444C7.53482 21.3436 9.96808 23.6241 12.9299 23.6241C15.6476 23.6241 17.9208 21.7032 18.4639 19.1454ZM18.5471 17.2916C18.299 15.2139 16.9236 13.4805 15.0504 12.7217C14.7457 12.598 14.5461 12.3023 14.5461 11.9725V2.61283H11.3136V11.9725C11.3136 12.3023 11.114 12.598 10.8093 12.7217C9.12117 13.4062 7.83706 14.8818 7.41845 16.6871C8.70418 16.3106 10.8029 16.0697 13.2749 17.2367C16.4832 18.7511 18.5067 17.3199 18.5067 17.3199C18.5197 17.3102 18.5334 17.3013 18.5471 17.2916Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13739">
<rect width="25.86" height="25.86" fill="white" transform="translate(0 0.188477)"/>
</clipPath>
</defs>
</svg>`}
      size={size}
    />
  )
}
