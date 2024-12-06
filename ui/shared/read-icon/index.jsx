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

const readSvg = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M17 5.50042V5.49851L8.99737 1L0.999969 5.49872V5.50051L0.999924 5.50054V16.9989H17.0002V5.50054L17 5.50042ZM16 6.12286V7.42H16.0002V15.1179L13.1351 11.6788L12.3661 12.3188L15.4322 15.9989H2.56795L5.634 12.3188L4.86499 11.6788L1.99994 15.1179V7.42H1.99997V6.12277L4.27751 7.42L9.00005 10.1099L13.7226 7.42L16 6.12286ZM15.0064 5.53575L8.99753 2.11293L2.99328 5.53551L6.30186 7.42L9.00005 8.95683L11.6983 7.42L15.0064 5.53575Z" fill="inherit"/>
</svg>`

export default function ReadIcon() {
  return <SVGIcon src={readSvg} title="read" color="inherit" />
}
