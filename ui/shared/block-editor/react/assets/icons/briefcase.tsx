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
      src={`<svg width="27" height="26" viewBox="0 0 27 26" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M7.96207 7.27305H3.86973C2.55895 7.27305 1.49707 8.33492 1.49707 9.6457C1.49707 12.4418 1.49707 18.2668 1.49707 21.0629C1.49707 22.3737 2.55895 23.4355 3.86973 23.4355H23.3682C24.6789 23.4355 25.7408 22.3737 25.7408 21.0629C25.7408 18.2668 25.7408 12.4418 25.7408 9.6457C25.7408 8.33492 24.6789 7.27305 23.3682 7.27305H19.2758V5.8863C19.2758 4.42117 18.0871 3.23242 16.6219 3.23242C14.8982 3.23242 12.3397 3.23242 10.616 3.23242C9.15082 3.23242 7.96207 4.42117 7.96207 5.8863V7.27305ZM24.1246 13.738H19.2758V14.5462C19.2758 14.9923 18.9138 15.3543 18.4677 15.3543C18.0216 15.3543 17.6596 14.9923 17.6596 14.5462V13.738H9.57832V14.5462C9.57832 14.9923 9.21628 15.3543 8.7702 15.3543C8.32411 15.3543 7.96207 14.9923 7.96207 14.5462V13.738H3.11332V21.0629C3.11332 21.4807 3.45193 21.8193 3.86973 21.8193H23.3682C23.786 21.8193 24.1246 21.4807 24.1246 21.0629V13.738ZM24.1246 12.1218V9.6457C24.1246 9.2279 23.786 8.8893 23.3682 8.8893H3.86973C3.45193 8.8893 3.11332 9.2279 3.11332 9.6457V12.1218H7.96207V11.3137C7.96207 10.8676 8.32411 10.5055 8.7702 10.5055C9.21628 10.5055 9.57832 10.8676 9.57832 11.3137V12.1218H17.6596V11.3137C17.6596 10.8676 18.0216 10.5055 18.4677 10.5055C18.9138 10.5055 19.2758 10.8676 19.2758 11.3137V12.1218H24.1246ZM17.6596 5.8863V7.27305H9.57832V5.8863C9.57832 5.31334 10.043 4.84867 10.616 4.84867H16.6219C17.1949 4.84867 17.6596 5.31334 17.6596 5.8863Z" fill="black"/>
</svg>`}
      size={size}
    />
  )
}
