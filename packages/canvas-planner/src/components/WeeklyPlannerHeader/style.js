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

  const classNames = {
    root: 'WeeklyPlannerHeader-styles__root',
    errorbox: 'WeeklyPlannerHeader-styles__errorbox',
  }

  const theme = {
    backgroundPrimary: variables.colors.backgroundLightest,
  }

  const css = `
  .${classNames.root} {
    position: sticky;
    z-index: 2;
    display: flex;
    justify-content: flex-end;
  }
  
  .${classNames.root}::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-image: linear-gradient(to top, rgba(255, 255, 255, 0), #fafafa);
  }
  
  .${classNames.errorbox} {
    background: ${theme.backgroundPrimary};
    z-index: 2;
    flex-grow: 1;
  }
  `

  return {css, classNames, theme}
}
