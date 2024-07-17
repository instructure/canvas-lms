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
<g clip-path="url(#clip0_1214_13760)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M8.45241 17.4532C8.33766 17.593 8.26816 17.7716 8.26816 17.9672V21.1997C8.26816 21.6458 8.6302 22.0078 9.07629 22.0078H9.48035V23.2814C9.48035 23.8011 9.68643 24.2989 10.0541 24.6666C10.4218 25.0343 10.9196 25.2403 11.4392 25.2403C12.4179 25.2403 13.8159 25.2403 14.7946 25.2403C15.3142 25.2403 15.812 25.0343 16.1797 24.6666C16.5474 24.2989 16.7535 23.8011 16.7535 23.2814V22.0078H17.1575C17.6036 22.0078 17.9657 21.6458 17.9657 21.1997V17.9672C17.9657 17.7716 17.8962 17.593 17.7814 17.4532C20.3165 15.8863 22.0063 13.0821 22.0063 9.88596C22.0063 4.97983 18.023 0.996582 13.1169 0.996582C8.21079 0.996582 4.22754 4.97983 4.22754 9.88596C4.22754 13.0821 5.91733 15.8863 8.45241 17.4532ZM15.1372 22.0078V23.2814C15.1372 23.372 15.1009 23.4592 15.037 23.5239C14.9724 23.5877 14.8851 23.6241 14.7946 23.6241H11.4392C11.3487 23.6241 11.2615 23.5877 11.1968 23.5239C11.133 23.4592 11.0966 23.372 11.0966 23.2814V22.0078H15.1372ZM13.121 18.7753H9.88441V20.3916H15.9454H15.9478H16.3494V18.7753H13.121ZM13.925 17.1146C17.5592 16.7122 20.39 13.6268 20.39 9.88596C20.39 5.872 17.1309 2.61283 13.1169 2.61283C9.10296 2.61283 5.84379 5.872 5.84379 9.88596C5.84379 13.6268 8.67465 16.7122 12.3088 17.1146V13.1185H10.6925C10.2465 13.1185 9.88441 12.7564 9.88441 12.3103C9.88441 11.8642 10.2465 11.5022 10.6925 11.5022H15.5413C15.9874 11.5022 16.3494 11.8642 16.3494 12.3103C16.3494 12.7564 15.9874 13.1185 15.5413 13.1185H13.925V17.1146Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13760">
<rect width="25.86" height="25.86" fill="white" transform="translate(0.186523 0.188477)"/>
</clipPath>
</defs>
</svg>
`}
      size={size}
    />
  )
}
