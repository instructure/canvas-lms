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

import {Container} from './Container'
import {ContainerSettings} from './ContainerSettings'
import {type ContainerProps, type ContainerLayout} from './types'

const ContainerIcon = `
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<g id="Icon">
<path id="Mask" fill-rule="evenodd" clip-rule="evenodd" d="M13.7647 0V1.05882H4.23529V0H0V4.23635H1.05882V13.7658H0V18H4.23529V16.9412H13.7647V18H18.0011V13.7658H16.9422V4.23635H18.0011V0H13.7647ZM14.8246 3.17647H16.9423V1.05882H14.8246V3.17647ZM1.05882 3.17647H3.17647V1.05882H1.05882V3.17647ZM2.11764 4.23636H4.23529V2.11765H13.7647V4.23636H15.8834V13.7658H13.7647V15.8824H4.23529V13.7658H2.11764V4.23636ZM14.8246 16.9412H16.9423V14.8235H14.8246V16.9412ZM1.05882 16.9412H3.17647V14.8235H1.05882V16.9412Z" fill="#2D3B45"/>
</g>
</svg>
`

export {Container, ContainerSettings, ContainerIcon, type ContainerProps, type ContainerLayout}
