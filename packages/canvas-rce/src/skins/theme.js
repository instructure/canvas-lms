/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {darken, lighten, alpha} from '@instructure/ui-color-utils'

// pull canvas theme values we need for the rce skin
export default function generator({borders, colors, forms, shadows, spacing, typography}) {
  const vars = {
    canvasBackgroundColor: colors.white,
    canvasTextColor: colors.textDarkest,
    canvasErrorColor: colors.textDanger,
    canvasWarningColor: colors.textWarning,
    canvasInfoColor: colors.textInfo,
    canvasSuccessColor: colors.textSuccess,
    canvasBorderColor: colors.borderMedium,
    toolbarButtonHoverBackground: darken(colors.backgroundLightest, 5), // copied from INSTUI "light" Button
    canvasBrandColor: colors.brand,

    activeMenuItemBackground: colors.backgroundBrand,
    activeMenuItemLabelColor: colors.textLightest,
    tableSelectorHighlightColor: alpha(lighten(colors.brand, 10), 50),

    canvasLinkColor: colors.link,
    canvasLinkDecoration: 'none',

    // the instui default button
    canvasButtonBackground: colors.backgroundLightest,
    canvasButtonBorderColor: 'transparent',
    canvasButtonColor: colors.textDarkest,
    canvasButtonHoverBackground: colors.backgroundLightest,
    canvasButtonHoverColor: colors.brand,
    canvasButtonActiveBackground: colors.backgroundLightest,
    canvasButtonFontWeight: typography.fontWeightNormal,
    canvasButtonFontSize: typography.fontSizeMedium,
    canvasButtonLineHeight: forms.inputHeightMedium,
    canvasButtonPadding: `0 ${spacing.small}`,

    // the instui primary button
    canvasPrimaryButtonBackground: colors.backgroundBrand,
    canvasPrimaryButtonColor: colors.textLightest,
    canvasPrimaryButtonBorderColor: 'transparent',
    canvasPrimaryButtonHoverBackground: darken(colors.backgroundBrand, 10),
    canvasPrimaryButtonHoverColor: colors.textLightest,

    // the instui secondary button
    canvasSecondaryButtonBackground: colors.backgroundLight,
    canvasSecondaryButtonColor: colors.textDarkest,
    canvasSecondaryButtonBorderColor: darken(colors.backgroundLight, 10),
    canvasSecondaryButtonHoverBackground: darken(colors.backgroundLight, 10),
    canvasSecondaryButtonHoverColor: colors.textDarkest,

    canvasFocusBorderColor: borders.brand,
    canvasFocusBorderWidth: borders.widthSmall, // canvas really uses widthMedium
    canvasFocusBoxShadow: `0 0 0 2px ${colors.brand}`,
    canvasEnabledColor: borders.brand,
    canvasEnabledBoxShadow: `inset 0 0 0.1875rem 0.0625rem ${darken(colors.borderLightest, 25)}`,

    canvasFontFamily: typography.fontFamily,
    canvasFontSize: '1rem',
    canvasFontSizeSmall: typography.fontSizeSmall,

    // modal dialogs
    canvasModalShadow: shadows.depth3,
    canvasModalHeadingPadding: spacing.medium,
    canvasModalHeadingFontSize: typography.fontSizeXLarge,
    canvasModalHeadingFontWeight: typography.fontWeightNormal,
    canvasModalBodyPadding: spacing.medium,
    canvasModalFooterPadding: spacing.small,
    canvasModalFooterBackground: colors.backgroundLight,
    canvasFormElementMargin: `0 0 ${spacing.medium} 0`,
    canvasFormElementLabelColor: colors.textDarkest,
    canvasFormElementLabelMargin: `0 0 ${spacing.small} 0`,
    canvasFormElementLabelFontSize: typography.fontSizeMedium,
    canvasFormElementLabelFontWeight: typography.fontWeightBold,

    // a11y button badge
    canvasBadgeBackgroundColor: colors.textInfo,
  }
  vars.tinySplitButtonChevronHoverBackground = darken(vars.toolbarButtonHoverBackground, 10)
  return vars
}

generator.canvas = function (variables) {
  return {
    canvasLinkColor: variables['ic-link-color'],
    canvasLinkDecoration: variables['ic-link-decoration'],
    canvasTextColor: variables['ic-brand-font-color-dark'],
    canvasBrandColor: variables['ic-brand-primary'],

    canvasFocusBorderColor: variables['ic-brand-primary'],
    canvasFocusBoxShadow: `0 0 0 2px ${variables['ic-brand-primary']}`,
    canvasEnabledColor: variables['ic-brand-primary'],

    canvasPrimaryButtonBackground: variables['ic-brand-primary'],
    canvasPrimaryButtonColor: variables['ic-brand-button--primary-text'],
    canvasPrimaryButtonHoverBackground: darken(variables['ic-brand-button--primary-bgd'], 10),

    activeMenuItemBackground: variables['ic-brand-button--primary-bgd'],
    activeMenuItemLabelColor: variables['ic-brand-button--primary-text'],
    tableSelectorHighlightColor: alpha(lighten(variables['ic-brand-primary'], 10), 50),
  }
}

generator['canvas-a11y'] = generator['canvas-high-contrast'] = function ({colors}) {
  return {
    canvasButtonBackground: colors.backgroundLight,
    canvasSecondaryButtonBorderColor: colors.borderMedium,
    canvasLinkDecoration: 'underline',
    canvasFocusBorderColor: colors.borderBrand,
    canvasFocusBoxShadow: `0 0 0 2px ${colors.brand}`,
    canvasBrandColor: colors.brand,
  }
}
