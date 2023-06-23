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

import {getThemeVars} from '../../getThemeVars'

export default function buildStyle() {
  /*
   * If the theme variables to be used when generating the styles below
   * are dependent on the actual theme in use, you can also pull out the
   * `key` property from the return from `getThemeVars()` and do a bit of
   * if or switch statement logic to get the result you want.
   */
  const {variables} = getThemeVars()

  const theme = {
    background: variables.colors.white,
  }

  const classNames = {
    root: 'UpdateItemTray-styles__root',
  }

  const css = `
  .${classNames.root} {
    background: ${theme.background};
    width: 19rem;
    max-width: 100%;
    box-sizing: border-box;
  }
  `
  return {css, classNames}
}
