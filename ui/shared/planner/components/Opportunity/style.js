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
    root: 'Opportunity-styles__root',
    oppNameAndTitle: 'Opportunity-styles__oppNameAndTitle',
    oppName: 'Opportunity-styles__oppName',
    title: 'Opportunity-styles__title',
    close: 'Opportunity-styles__close',
    footer: 'Opportunity-styles__footer',
    status: 'Opportunity-styles__status',
    points: 'Opportunity-styles__points',
    pointsNumber: 'Opportunity-styles__pointsNumber',
    due: 'Opportunity-styles__due',
    dueText: 'Opportunity-styles__dueText',
  }

  const theme = {
    lineHeight: variables.typography.lineHeightCondensed,
    fontSize: variables.typography.fontSizeMedium,
    fontFamily: variables.typography.fontFamily,
    fontWeight: variables.typography.fontWeightNormal,
    color: variables.colors.licorice,
    secondaryColor: variables.colors.slate,
    background: variables.colors.white,
    namePaddingTop: variables.spacing.xxSmall,
    nameFontSize: variables.typography.fontSizeSmall,
    statusPadding: variables.spacing.small,
    dueFontSize: variables.typography.fontSizeXSmall,
    dueMargin: variables.spacing.xxSmall,
    dueTextFontWeight: variables.typography.fontWeightBold,
    footerPadding: variables.spacing.xSmall,
    pointsFontSize: variables.typography.fontSizeXSmall,
    pointsNumberFontSize: variables.typography.fontSizeLarge,
    pointsLineHeight: variables.typography.lineHeightFit,
    titleMargin: variables.spacing.xSmall,
    closeButtonIconSize: '1.75rem',
  }

  const css = `
  .${classNames.root} {
    position: relative;
    font-size: ${theme.fontSize};
    font-family: ${theme.fontFamily};
    font-weight: ${theme.fontWeight};
    color: ${theme.color};
    background: ${theme.background};
    padding: ${theme.padding};
    box-sizing: border-box;
    line-height: ${theme.lineHeight};
  }
  
  .${classNames.oppNameAndTitle} {
    max-width: 16.5rem;
  }
  
  .${classNames.oppName} {
    box-sizing: border-box;
    min-width: 1px;
    flex: 1;
    padding-top: ${theme.namePaddingTop};
    text-transform: uppercase;
    letter-spacing: 0.0625rem;
    color: ${theme.secondaryColor};
    font-size: ${theme.nameFontSize};
    margin-right: ${theme.closeButtonIconSize};
  }
  
  .${classNames.title} {
    margin-bottom: ${theme.titleMargin};
  }
  
  .${classNames.close} {
    position: absolute;
    top: 0;
    offset-inline-end: 0;
  }
  [dir="ltr"] .${classNames.close} {
    right: 0;
  }
  [dir="rtl"] .${classNames.close} {
    left: 0;
  }
  
  .${classNames.oppName},
  .${classNames.title} {
    overflow-wrap: break-word;
    word-wrap: break-word;
    hyphens: auto;
  }
  
  .${classNames.footer} {
    box-sizing: border-box;
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    padding-inline-end: ${theme.footerPadding};
  }
  
  .${classNames.status} {
    box-sizing: border-box;
    min-width: 1px;
    flex-grow: 1;
    padding-inline-end: ${theme.statusPadding};
  }
  
  .${classNames.points} {
    box-sizing: border-box;
    min-width: 1px;
    flex-shrink: 0;
    text-align: end;
    color: ${theme.secondaryColor};
    text-transform: uppercase;
    font-size: ${theme.pointsFontSize};
    line-height: ${theme.pointsLineHeight};
  }
  
  .${classNames.pointsNumber} {
    display: block;
    font-size: ${theme.pointsNumberFontSize};
  }
  
  .${classNames.due} {
    margin-top: ${theme.dueMargin};
    font-size: ${theme.dueFontSize};
    color: ${theme.secondaryColor};
  }
  
  .${classNames.dueText} {
    font-weight: ${theme.dueTextFontWeight};
  }
  `

  return {css, classNames, theme}
}
