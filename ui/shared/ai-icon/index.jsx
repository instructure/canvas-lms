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

const aiSvg = `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<g id="Icon" clip-path="url(#clip0_705_16200)">
<path id="Vector" fill-rule="evenodd" clip-rule="evenodd" d="M11.4308 6.56918L9 0L6.56918 6.56918L0 9L6.56918 11.4308L9 18L11.4308 11.4308L18 9L11.4308 6.56918ZM10.6334 7.36658L9 2.95233L7.36658 7.36658L2.95233 9L7.36658 10.6334L9 15.0477L10.6334 10.6334L15.0477 9L10.6334 7.36658Z" fill="#273540"/>
<path id="Vector_2" d="M15 0L15.8103 2.18973L18 3L15.8103 3.81027L15 6L14.1897 3.81027L12 3L14.1897 2.18973L15 0Z" fill="#273540"/>
</g>
<defs>
<clipPath id="clip0_705_16200">
<rect width="18" height="18" fill="white"/>
</clipPath>
</defs>
</svg>
`
export default function AiIcon() {
  return <SVGIcon src={aiSvg} title="ai" color="inherit" />
}
