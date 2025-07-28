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
      src={`<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36" fill="none">
  <path d="M5.5 12C5.5 10.5575 5.50212 9.57625 5.60092 8.84143C5.69584 8.13538 5.86322 7.80836 6.08579 7.58579C6.30836 7.36322 6.63538 7.19584 7.34143 7.10092C8.07625 7.00212 9.05752 7 10.5 7H25.5C26.9425 7 27.9237 7.00212 28.6586 7.10092C29.3646 7.19584 29.6916 7.36322 29.9142 7.58579L30.6153 6.88466L29.9142 7.58579C30.1368 7.80836 30.3042 8.13538 30.3991 8.84143C30.4979 9.57625 30.5 10.5575 30.5 12V24.5H5.5V12Z" stroke="currentColor" stroke-width="2" fill="transparent" />
  <path d="M5.5 24.5C4.39543 24.5 3.5 25.3954 3.5 26.5C3.5 28.1569 4.84315 29.5 6.5 29.5H29.5C31.1569 29.5 32.5 28.1569 32.5 26.5C32.5 25.3954 31.6046 24.5 30.5 24.5H5.5Z" stroke="currentColor" stroke-width="2" fill="transparent" />
</svg>`}
      size={size}
    />
  )
}
