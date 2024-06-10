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

import {ColumnsSection} from './ColumnsSection'
import {NoSections, type ColumnsSectionVariant} from './NoSections'
import {ColumnsSectionToolbar} from './ColumnsSectionToolbar'

const ColumnsSectionIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18" fill="none">
<g clip-path="url(#clip0_1375_197267)">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M16.3125 0C17.2429 0 18 0.757125 18 1.6875V16.3125C18 17.2429 17.2429 18 16.3125 18H1.6875C0.757125 18 0 17.2429 0 16.3125V1.6875C0 0.757125 0.757125 0 1.6875 0H16.3125ZM16.875 16.3125V1.6875C16.875 1.37813 16.623 1.125 16.3125 1.125H6.75V16.875H16.3125C16.623 16.875 16.875 16.6219 16.875 16.3125ZM1.6875 16.875H5.625V12.375H1.125V16.3125C1.125 16.6219 1.377 16.875 1.6875 16.875ZM1.125 11.25H5.625V6.75H1.125V11.25ZM1.6875 1.125C1.377 1.125 1.125 1.37813 1.125 1.6875V5.625H5.625V1.125H1.6875ZM10.7205 4.78125H12.9705V7.875H16.0642V10.125H12.9705V13.2188H10.7205V10.125H7.62671V7.875H10.7205V4.78125Z" fill="#2D3B45"/>
</g>
<defs>
  <clipPath id="clip0_1375_197267">
    <rect width="18" height="18" fill="white"/>
  </clipPath>
</defs>
</svg>`

export {
  ColumnsSection,
  NoSections,
  ColumnsSectionToolbar,
  ColumnsSectionIcon,
  type ColumnsSectionVariant,
}
