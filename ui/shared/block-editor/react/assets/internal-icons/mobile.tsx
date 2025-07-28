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
  <path d="M21.6339 5.36612L20.9268 6.07322L21.6339 5.36612C21.3805 5.11274 21.0865 5.04213 20.9076 5.01807C20.7696 4.99953 20.6169 4.9998 20.5235 4.99997C20.5152 4.99999 20.5073 5 20.5 5H15.5C15.4927 5 15.4848 4.99999 15.4765 4.99997C15.3831 4.9998 15.2304 4.99953 15.0924 5.01807C14.9135 5.04213 14.6195 5.11274 14.3661 5.36612C14.1127 5.6195 14.0421 5.91347 14.0181 6.09243C13.9995 6.23037 13.9998 6.38313 14 6.47653C14 6.48484 14 6.49268 14 6.5C14 6.51294 14 6.52608 14 6.53938C13.9999 6.73926 13.9997 6.97723 14.0272 7.18188C14.0604 7.42893 14.1493 7.77067 14.4393 8.06066C14.7293 8.35065 15.0711 8.43956 15.3181 8.47278C15.5228 8.50029 15.7607 8.50014 15.9606 8.50002C15.9739 8.50001 15.9871 8.5 16 8.5H20C20.0129 8.5 20.0261 8.50001 20.0394 8.50002C20.2393 8.50014 20.4772 8.50029 20.6819 8.47278C20.9289 8.43956 21.2707 8.35065 21.5607 8.06066C21.8507 7.77067 21.9396 7.42893 21.9728 7.18188C22.0003 6.97723 22.0001 6.73926 22 6.53938C22 6.52608 22 6.51295 22 6.5C22 6.49268 22 6.48484 22 6.47653C22.0002 6.38312 22.0005 6.23036 21.9819 6.09243C21.9579 5.91347 21.8873 5.6195 21.6339 5.36612Z" stroke="currentColor" stroke-width="2" fill="transparent" />
  <rect x="9" y="4.5" width="18" height="27" rx="2" stroke="currentColor" stroke-width="2" fill="transparent" />
  <circle cx="18" cy="27" r="1.5" fill="#273540"/>
</svg>`}
      size={size}
    />
  )
}
