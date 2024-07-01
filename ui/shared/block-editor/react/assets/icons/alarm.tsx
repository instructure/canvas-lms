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
      src={`<svg width="26" height="26" viewBox="0 0 26 26" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1214_13706)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M12.1219 2.42436V3.26561C7.14789 3.67695 3.23253 7.8493 3.23253 12.93C3.23253 15.8408 4.51825 18.4543 6.55149 20.2322L4.17642 23.7952C3.92913 24.167 4.02934 24.6688 4.40027 24.9161C4.772 25.1634 5.27385 25.0632 5.52114 24.6922L7.85419 21.1931C9.33064 22.1022 11.0697 22.6275 12.93 22.6275C14.7903 22.6275 16.5294 22.1022 18.0059 21.1931L20.3389 24.6922C20.5862 25.0632 21.088 25.1634 21.4598 24.9161C21.8307 24.6688 21.9309 24.167 21.6836 23.7952L19.3086 20.2322C21.3418 18.4543 22.6275 15.8408 22.6275 12.93C22.6275 7.8493 18.7122 3.67695 13.7381 3.26561V2.42436H14.5463C14.9924 2.42436 15.3544 2.06232 15.3544 1.61623C15.3544 1.17015 14.9924 0.808105 14.5463 0.808105H11.3138C10.8677 0.808105 10.5056 1.17015 10.5056 1.61623C10.5056 2.06232 10.8677 2.42436 11.3138 2.42436H12.1219ZM12.93 4.84873C17.3901 4.84873 21.0113 8.46994 21.0113 12.93C21.0113 17.39 17.3901 21.0112 12.93 21.0112C8.46998 21.0112 4.84878 17.39 4.84878 12.93C4.84878 8.46994 8.46998 4.84873 12.93 4.84873ZM12.1219 8.88936V12.93C12.1219 13.1441 12.2068 13.3502 12.3587 13.5013L14.7831 15.9257C15.0982 16.2409 15.6106 16.2409 15.9257 15.9257C16.2409 15.6105 16.2409 15.0982 15.9257 14.783L13.7381 12.5954V8.88936C13.7381 8.44327 13.3761 8.08123 12.93 8.08123C12.4839 8.08123 12.1219 8.44327 12.1219 8.88936ZM18.8237 3.80382L22.0562 7.03633C22.3713 7.35149 22.8837 7.35149 23.1989 7.03633C23.514 6.72116 23.514 6.2088 23.1989 5.89364L19.9664 2.66114C19.6512 2.34597 19.1388 2.34597 18.8237 2.66114C18.5085 2.97631 18.5085 3.48866 18.8237 3.80382ZM5.89368 2.66114L2.66118 5.89364C2.34601 6.2088 2.34601 6.72116 2.66118 7.03633C2.97635 7.35149 3.4887 7.35149 3.80387 7.03633L7.03637 3.80382C7.35154 3.48866 7.35154 2.97631 7.03637 2.66114C6.7212 2.34597 6.20885 2.34597 5.89368 2.66114Z" fill="black"/>
</g>
<defs>
<clipPath id="clip0_1214_13706">
<rect width="25.86" height="25.86" fill="white"/>
</clipPath>
</defs>
</svg>`}
      size={size}
    />
  )
}
