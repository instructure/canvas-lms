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
  const {variables, key} = getThemeVars()

  let themeAdditionalStyles = {}
  switch (key) {
    case 'canvas':
      themeAdditionalStyles = {
        groupColor: variables['ic-brand-primary'],
        titleColor: variables['ic-brand-primary'],
      }
      break
    case 'canvas-a11y':
    case 'modern-a11y':
      themeAdditionalStyles = {
        heroTextDecoration: 'underline',
        heroTextDecorationHover: 'none',
        titleColor: variables.colors.licorice,
      }
      break
  }

  const classNames = {
    root: 'Grouping-styles__root',
    title: 'Grouping-styles__title',
    hero: 'Grouping-styles__hero',
    groupingName: 'Grouping-styles__groupingName',
    overlay: 'Grouping-styles__overlay',
    heroHover: 'Grouping-styles__heroHover',
    withImage: 'Grouping-styles__withImage',
    small: 'Grouping-styles__small',
    medium: 'Grouping-styles__medium',
    items: 'Grouping-styles__items',
  }

  const theme = {
    fontFamily: variables.typography.fontFamily,
    lineHeight: variables.typography.lineHeightCondensed,
    margin: `${variables.spacing.medium} 0 0 0`,

    groupColor: variables.colors.brand,

    borderTopWidth: variables.borders.widthSmall,
    borderTopWidthTablet: variables.borders.widthMedium,

    heroMinHeight: '7rem',
    heroWidth: '12rem',
    heroWidthLarge: '14rem',
    heroPadding: '0.0625rem',
    heroColor: variables.colors.brand,
    heroBorderRadius: variables.borders.radiusMedium,

    overlayOpacity: 0.75,

    titleFontSize: variables.typography.fontSizeXSmall,
    titleFontSizeTablet: '0.875rem',
    titleFontWeight: variables.typography.fontWeightBold,
    titleLetterSpacing: '0.0625rem',
    titleBackground: variables.colors.white,
    titleTextTransform: 'uppercase',
    titlePadding: `${variables.spacing.xxSmall} ${variables.spacing.xSmall}`,
    titleOverflowGradientHeight: variables.spacing.xxSmall,
    titleTextDecoration: 'none',
    titleTextDecorationHover: 'underline',
    titleColor: variables.colors.brand,
    ...themeAdditionalStyles,
    ...variables.media,
  }

  const css = `
  .${classNames.root} {
    font-family: ${theme.fontFamily};
    margin: ${theme.margin};
    border-color: ${theme.groupColor};
    color: ${theme.groupColor};
    line-height: ${theme.lineHeight};
    position: relative;
    display: flex;
  }
  
  .${classNames.title} {
    position: relative;
    z-index: 1;
    flex: 1;
    box-sizing: border-box;
    text-align: center;
    padding: ${theme.titlePadding};
    background-color: ${theme.titleBackground};
    text-transform: ${theme.titleTextTransform};
    text-decoration: ${theme.titleTextDecoration};
    font-size: ${theme.titleFontSize};
    font-weight: ${theme.titleFontWeight};
    color: ${theme.titleColor};
    border-top-left-radius: 0.125rem;
    min-width: 1px;
    overflow: hidden;
    max-height: 3rem;
    overflow-wrap: break-word;
    word-wrap: break-word;
    hyphens: auto;
  }
  .${classNames.title}::after {
    content: "";
    width: 100%;
    height: ${theme.titleOverflowGradientHeight};
    position: absolute;
    bottom: 0;
    left: 0;
    background: linear-gradient(to bottom, rgba(255, 255, 255, 0) 0%, ${theme.titleBackground} 100%);
  }
  
  .${classNames.hero} {
    position: relative;
    display: flex;
    flex: 0 0 ${theme.heroWidth};
    background-repeat: no-repeat;
    background-position: center center;
    background-size: cover;
    align-items: flex-start;
    justify-content: center;
    box-sizing: border-box;
    outline: none;
    padding: ${theme.heroPadding};
    text-decoration: none;
    min-width: 1px;
  }
  .${classNames.hero} .${classNames.groupingName} {
    text-decoration: ${theme.heroLinkTextDecoration};
  }
  
  .${classNames.hero},
  .${classNames.overlay} {
    border-bottom-inline-start-radius: ${theme.heroBorderRadius};
    border-top-inline-start-radius: ${theme.heroBorderRadius};
  }
  
  .${classNames.heroHover}:focus, .${classNames.heroHover}:hover {
    text-decoration: none;
  }
  .${classNames.heroHover}:focus .${classNames.title}, .${classNames.heroHover}:hover .${classNames.title} {
    text-decoration: ${theme.titleTextDecorationHover};
  }
  
  .${classNames.overlay} {
    background-color: ${theme.groupColor};
    opacity: 1;
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
  }
  .${classNames.overlay}.${classNames.withImage} {
    opacity: ${theme.overlayOpacity};
  }
  
  .${classNames.items} {
    flex: 1;
    list-style-type: none;
    margin: 0;
    padding: 0;
    border-top: ${theme.borderTopWidth} solid;
    border-color: ${theme.groupColor};
    color: ${theme.groupColor};
    min-width: 1px;
  }
  
  .${classNames.medium}.${classNames.root}, .${classNames.small}.${classNames.root} {
    display: block;
    margin: 0;
  }
  .${classNames.medium} .${classNames.hero}, .${classNames.medium} .${classNames.overlay}, .${classNames.small} .${classNames.hero}, .${classNames.small} .${classNames.overlay} {
    border-radius: 0;
    background-color: transparent;
  }
  .${classNames.medium} .${classNames.hero}, .${classNames.small} .${classNames.hero} {
    display: block;
    flex: none;
    min-height: unset;
    line-height: 2rem;
  }
  .${classNames.medium} .${classNames.title}, .${classNames.small} .${classNames.title} {
    font-size: ${theme.titleFontSizeTablet};
    padding-inline-start: 0;
  }
  .${classNames.medium} .${classNames.items}, .${classNames.small} .${classNames.items} {
    border-top-width: ${theme.borderTopWidthTablet};
  }
  `

  return {css, classNames, theme}
}
