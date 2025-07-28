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
      src={`<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_10_3900)">
<path d="M0 0V1.63636H1.63636V0H0ZM3.27273 0V1.63636H4.90909V0H3.27273ZM6.54545 0V1.63636H8.18182V0H6.54545ZM9.81818 0V1.63636H11.4545V0H9.81818ZM13.0909 0V1.63636H14.7273V0H13.0909ZM16.3636 0V1.63636H18V0H16.3636ZM0 3.27273V4.90909H1.63636V3.27273H0ZM16.3636 3.27273V4.90909H18V3.27273H16.3636ZM7.36364 4.90909V6.54545H10.2784L7.00568 9.81818H0V18H8.18182V10.9943L11.4545 7.72159V10.6364H13.0909V4.90909H7.36364ZM0 6.54545V8.18182H1.63636V6.54545H0ZM16.3636 6.54545V8.18182H18V6.54545H16.3636ZM16.3636 9.81818V11.4545H18V9.81818H16.3636ZM1.63636 11.4545H6.54545V16.3636H1.63636V11.4545ZM16.3636 13.0909V14.7273H18V13.0909H16.3636ZM9.81818 16.3636V18H11.4545V16.3636H9.81818ZM13.0909 16.3636V18H14.7273V16.3636H13.0909ZM16.3636 16.3636V18H18V16.3636H16.3636Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_10_3900">
<rect width="18" height="18" fill="white"/>
</clipPath>
</defs>
</svg>`}
      size={size}
    />
  )
}
