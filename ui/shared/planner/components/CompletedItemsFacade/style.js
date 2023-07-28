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
    root: 'CompletedItemsFacade-styles__root',
    small: 'CompletedItemsFacade-styles__small',
    k5Layout: 'CompletedItemsFacade-styles__k5Layout',
    contentPrimary: 'CompletedItemsFacade-styles__contentPrimary',
    contentSecondary: 'CompletedItemsFacade-styles__contentSecondary',
    activityIndicator: 'CompletedItemsFacade-styles__activityIndicator',
    showLabel: 'CompletedItemsFacade-styles__showLabel',
  }

  const theme = {
    fontFamily: variables.typography.fontFamily,
    color: variables.colors.licorice,

    padding: variables.spacing.small,
    paddingMedium: variables.spacing.small,
    paddingLarge: `${variables.spacing.small} ${variables.spacing.medium}`,

    borderWidth: variables.borders.widthSmall,
    borderColor: variables.colors.tiara,
    bottomMarginPhoneUp: variables.spacing.xSmall,

    gutterWidth: variables.spacing.medium,
    buttonPadding: variables.spacing.small,

    labelColor: variables.colors.brand,
  }

  const css = `
  .${classNames.root} {
    display: flex;
    flex: 1;
    align-items: center;
    font-family: ${theme.fontFamily};
    color: ${theme.color};
    box-sizing: border-box;
    padding: ${theme.padding};
    border-bottom: ${theme.borderWidth} solid ${theme.borderColor};
  }

  .${classNames.root}.${classNames.small}.${classNames.k5Layout} > .${classNames.contentPrimary} {
    margin-inline-start: 25px;
  }
  
  .${classNames.activityIndicator} {
    padding-inline-end: 0;
    padding-inline-start: 0;
  }
  
  .${classNames.showLabel} {
    margin-inline-start: ${theme.gutterWidth};
  }
  
  .${classNames.contentPrimary} {
    flex: 0 0 50%;
    margin-bottom: 0;
    margin-inline-start: ${theme.gutterWidth};
    box-sizing: border-box;
    min-width: 1px;
  }
  
  .${classNames.contentSecondary} {
    flex: 1 0;
    justify-content: flex-end;
    box-sizing: border-box;
    min-width: 1px;
    text-align: end;
  }
  
  .${classNames.activityIndicator} + .${classNames.contentPrimary} {
    margin-inline-start: calc(${theme.gutterWidth} - ${theme.buttonPadding} - ${theme.activityIndicatorWidth});
  }
  
  .${classNames.small} {
    padding-left: 0;
    padding-right: 0;
  }

  .${classNames.small} .${classNames.contentPrimary} {
    margin-inline-start: 10px;
    flex-basis: auto;
  }
  
  .${classNames.small} .${classNames.contentSecondary} {
    display: none;
  }
  `
  return {css, classNames, theme}
}
