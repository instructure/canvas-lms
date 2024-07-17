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
</svg>
`
const unreadSvg = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M0 3.5V16.5002H16.0003V8.97009H15.0002V14.6192L12.1352 11.1801L11.3662 11.8201L14.4322 15.5002H1.56803L4.63408 11.8201L3.86506 11.1801L1.00002 14.6192V6.20404L8.00013 12.6812L12.5992 8.42708L11.9212 7.69207L8.00013 11.3181L1.00002 4.84102V4.50002H10.5302V3.5H0ZM17.2139 2.47512C16.6729 1.88411 15.9338 1.53911 15.1338 1.50311C14.3388 1.4671 13.5668 1.74511 12.9748 2.28612C12.3838 2.82713 12.0388 3.56614 12.0028 4.36615C11.9678 5.16717 12.2458 5.93418 12.7868 6.52519C13.3278 7.1162 14.0658 7.4612 14.8668 7.4972C14.9128 7.4992 14.9578 7.5002 15.0038 7.5002C15.7538 7.5002 16.4678 7.2242 17.0249 6.71419C17.6169 6.17318 17.9619 5.43417 17.9969 4.63416C18.0329 3.83314 17.7549 3.06613 17.2139 2.47512Z" fill="inherit"/>
</svg>
`

export const ReadIcon = () => <SVGIcon src={readSvg} title="read" color="inherit" />
export const UnreadIcon = () => <SVGIcon src={unreadSvg} title="unread" color="inherit" />
