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
    root: 'Opportunities-styles__root',
    tabs_container: 'Opportunities-styles__tabs_container',
    header: 'Opportunities-styles__header',
    list: 'Opportunities-styles__list',
    item: 'Opportunities-styles__item',
    loading: 'Opportunities-styles__loading',
  }

  const theme = {
    padding: `${variables.spacing.xSmall} ${variables.spacing.small} ${variables.spacing.small}`,
    borderBottom: `${variables.borders.widthSmall} ${variables.borders.style} ${variables.colors.tiara}`,
    borderColor: variables.colors.tiara,
    borderWidth: variables.borders.widthSmall,
    borderStyle: variables.borders.style,
    itemMargin: variables.spacing.small,
    itemPadding: variables.spacing.xxSmall,
    lineHeight: variables.typography.lineHeightCondensed,
  }

  const css = `
  .${classNames.root} {
    padding: ${theme.padding};
    max-height: 36rem;
    overflow: auto;
    box-sizing: border-box;
    width: 20rem;
    max-width: 100%;
    line-height: ${theme.lineHeight};
  }
  
  .${classNames.header} {
    border-bottom: ${theme.borderBottom};
    text-align: center;
    margin-bottom: 0.25rem;
  }
  
  .${classNames.list} {
    list-style-type: none;
    color: ${theme.color};
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  
  .${classNames.item} {
    margin: 0;
    padding: 0;
  }
  .${classNames.item}:not(:last-of-type) {
    margin-bottom: ${theme.itemMargin};
  }
  .${classNames.item}:not(:first-of-type) {
    border-top: ${theme.borderWidth} ${theme.borderStyle} ${theme.borderColor};
    padding-top: ${theme.itemPadding};
  }
  
  .${classNames.loading} {
    text-align: center;
  }
  
  #${classNames.tabs_container} > div:first-child {
    display: inline-block;
  }
  `

  return {css, classNames, theme}
}
