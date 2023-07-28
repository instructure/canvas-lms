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
    root: 'MissingAssignments-styles__root',
    icon: 'MissingAssignments-styles__icon',
    medium: 'MissingAssignments-styles__medium',
    small: 'MissingAssignments-styles__small',
  }

  const theme = {
    toggleMarginTop: variables.spacing.small,
    toggleButtonMarginTop: variables.spacing.small,
    toggleButtonMarginStart: variables.spacing.large,
    moreButtonMarginStart: variables.spacing.medium,
    moreButtonMarginVertical: variables.spacing.small,
  }

  const css = `
  .${classNames.root} {
    display: flex;
    align-items: center;
    position: relative;
    margin-top: ${theme.toggleMarginTop};
  }
  .${classNames.root} > :last-child {
    width: 100%;
  }
  .${classNames.root} > div > button {
    margin: ${theme.toggleButtonMarginTop} 0;
  }
  .${classNames.root} > div > button svg {
    margin-inline-start: ${theme.toggleButtonMarginStart};
  }
  
  .${classNames.icon} {
    position: absolute;
    top: calc(${theme.toggleMarginTop} - 2px);
    left: 0;
  }
  
  .${classNames.medium}.${classNames.root},
  .${classNames.small}.${classNames.root} {
    margin-inline-start: 0;
  }
  `

  return {css, classNames, theme}
}
