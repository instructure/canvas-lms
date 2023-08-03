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

import {darken} from '@instructure/ui-color-utils'
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
        background: variables['ic-brand-primary'],
        backgroundHover: darken(variables['ic-brand-primary'], 5),
        focusRingColor: variables['ic-brand-primary'],
      }
      break
  }

  const classNames = {
    root: 'StickyButton-styles__root',
    icon: 'StickyButton-styles__icon',
    layout: 'StickyButton-styles__layout',
    newActivityButton: 'StickyButton-styles__newActivityButton',
    directionUp: 'StickyButton-styles__direction--up',
    directionDown: 'StickyButton-styles__direction--down',
  }

  const theme = {
    fontSize: variables.typography.fontSizeXSmall,
    fontFamily: variables.typography.fontFamily,
    fontWeight: variables.typography.fontWeightNormal,
    color: variables.colors.white,
    background: variables.colors.brand,
    backgroundHover: darken(variables.colors.brand, 5),
    padding: `0 ${variables.spacing.small}`,
    textTransform: 'uppercase',
    lineHeight: variables.spacing.medium,
    iconMargin: variables.spacing.xxSmall,
    hasIconRightPadding: variables.spacing.xSmall,
    borderRadius: variables.borders.radiusMedium,
    focusRingWidth: variables.borders.widthSmall,
    focusRingColor: variables.colors.brand,
    ...themeAdditionalStyles,
  }

  const css = `
  .${classNames.root} {
    box-sizing: border-box;
    display: block;
    border: none;
    color: ${theme.color};
    background-color: ${theme.background};
    padding: 0;
    font-size: ${theme.fontSize};
    font-weight: ${theme.fontWeight};
    font-family: ${theme.fontFamily};
    text-transform: ${theme.textTransform};
    line-height: ${theme.lineHeight};
    white-space: nowrap;
    cursor: pointer;
    user-select: none;
    touch-action: manipulation;
    appearance: none;
    transition: background-color 0.2s;
    outline: none;
    overflow: visible;
    border-bottom-left-radius: ${theme.borderRadius};
    border-bottom-right-radius: ${theme.borderRadius};
    position: fixed;
  }
  .${classNames.root}::before {
    content: "";
    box-sizing: border-box;
    width: calc(100% + 0.5rem);
    height: calc(100% + 0.5rem);
    border: ${theme.focusRingWidth} solid ${theme.focusRingColor};
    position: absolute;
    top: -0.25rem;
    /* the placement and radii are symetrical, so no need to replace left/right with start/end */
    left: -0.25rem;
    border-bottom-left-radius: ${theme.borderRadius};
    border-bottom-right-radius: ${theme.borderRadius};
    transform: scale(0.25);
    opacity: 0;
    transition: all 0.2s ease-out;
  }
  .${classNames.root}:focus::before {
    opacity: 1;
    transform: scale(1);
  }
  .${classNames.root}:focus, .${classNames.root}:hover {
    background-color: ${theme.backgroundHover};
  }
  .${classNames.root}:focus .${classNames.icon}, .${classNames.root}:hover .${classNames.icon} {
    transform: translate3d(0, -0.0625rem, 0) scale(1.2);
  }
  .${classNames.root}[aria-disabled] {
    cursor: not-allowed;
    pointer-events: none;
    opacity: 0.5;
  }

  .${classNames.icon} {
    display: block;
    font-size: 0.75rem;
    margin-inline-start: ${theme.iconMargin};
    transform: translate3d(0, -0.0625rem, 0);
    transition: all 0.2s;
  }

  .${classNames.directionUp} .${classNames.layout},
  .${classNames.directionDown} .${classNames.layout} {
    padding-inline-end: ${theme.hasIconRightPadding};
  }

  .${classNames.layout} {
    box-sizing: border-box;
    display: flex;
    align-items: center;
    width: 100%;
    height: 100%;
    padding: ${theme.padding};
  }

  .${classNames.newActivityButton} {
    inset-inline-end: 0;
    top: 100%;
    position: absolute;
  }
  `

  return {css, classNames, theme}
}
