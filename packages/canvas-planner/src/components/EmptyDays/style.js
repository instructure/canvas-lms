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
    root: 'EmptyDays-styles__root',
    small: 'EmptyDays-styles__small',
    nothingPlanned: 'EmptyDays-styles__nothingPlanned',
    nothingPlannedContent: 'EmptyDays-styles__nothingPlannedContent',
    nothingPlannedContainer: 'EmptyDays-styles__nothingPlannedContainer',
  }

  const theme = {
    fontSize: variables.typography.fontSizeMedium,
    fontFamily: variables.typography.fontFamily,
    fontWeight: variables.typography.fontWeightNormal,
    lineHeight: variables.typography.lineHeightCondensed,
    color: variables.colors.oxford,
    background: variables.colors.white,
    marginTop: variables.spacing.large,
    borderWidth: variables.borders.widthSmall,
    paddingWidth: variables.spacing.small,
  }

  const css = `
  .${classNames.root} {
    position: relative;
    font-size: ${theme.fontSize};
    font-family: ${theme.fontFamily};
    font-weight: ${theme.fontWeight};
    line-height: ${theme.lineHeight};
    color: ${theme.color};
    background: ${theme.background};
    margin-top: ${theme.marginTop};
    border-bottom-width: ${theme.borderWidth};
    border-bottom-style: solid;
  }
  
  .${classNames.nothingPlannedContent} {
    padding: ${theme.paddingWidth} 0 0 0;
  }
  
  .${classNames.nothingPlannedContainer} {
    position: absolute;
    left: 0;
    top: 0;
    right: 0;
    bottom: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  
  .${classNames.nothingPlanned} {
    padding-top: ${theme.paddingWidth};
  }
  
  .${classNames.small} .${classNames.nothingPlannedContent} {
    display: flex;
    flex-direction: column-reverse;
    justify-content: flex-start;
    padding: ${theme.paddingWidth} 0;
  }
  .${classNames.small} .${classNames.nothingPlannedContainer} {
    position: static;
  }
  .${classNames.small} .${classNames.nothingPlanned} {
    padding-top: 0;
  }
  `

  return {css, classNames, theme}
}
