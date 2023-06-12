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
    activityIndicator: 'NotificationBadge-styles__activityIndicator',
    hasBadge: 'NotificationBadge-styles__hasBadge',
    small: 'NotificationBadge-styles__small',
  }

  const theme = {
    activityIndicatorPadding: variables.spacing.small,
    activityIndicatorWidth: variables.spacing.small,
    activityIndicatorBorderSize: '1rem',
    activityIndicatorBackground: variables.colors.white,
  }

  const css = `
  .${classNames.activityIndicator} {
    width: ${theme.activityIndicatorWidth};
    padding: ${theme.activityIndicatorPadding};
  }
  .${classNames.activityIndicator}.${classNames.hasBadge} {
    background: transparent;
    width: auto;
    height: auto;
    align-items: center;
    justify-content: center;
    position: static;
    display: flex;
    top: auto;
    right: auto;
    z-index: 1;
    border-radius: 0;
  }
  
  .${classNames.small}.${classNames.activityIndicator} {
    padding: 0;
  }
  `

  return {css, classNames, theme}
}
