// @ts-nocheck
/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import * as rawInstUiIcons from '@instructure/ui-icons/es/svg'

/**
 * All inst-ui icons as an array.
 *
 * Note that this does require including these all in the built modules, but it appears that they were already
 * present, as testing with and without this didn't yield much difference in module size.
 */
export const instUiIconsArray = Object.values(rawInstUiIcons) as Array<InstUiIcon>

/**
 * Type for inst ui icons
 */
export interface InstUiIcon {
  variant: 'Line' | 'Solid'
  glyphName: string

  /**
   * SVG code for the icon
   */
  src: string
  deprecated: boolean
}
