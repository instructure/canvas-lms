/* Global variables (colors, typography, spacing, etc.) are defined in lib/themes */

/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
export default function generator ({ borders, colors, media, spacing, typography }) {
  return {
    fontFamily: typography.fontFamily,
    lineHeight: typography.lineHeightCondensed,
    margin: `${spacing.medium} 0 0 0`,

    groupColor: colors.brand,

    borderTopWidth: borders.widthSmall,
    borderTopWidthTablet: borders.widthMedium,

    heroMinHeight: '7rem',
    heroWidth: '12rem',
    heroWidthLarge: '14rem',
    heroPadding: '0 0.0625rem',
    heroColor: colors.brand,
    heroBorderRadius: borders.radiusMedium,

    overlayOpacity: 0.75,

    titleFontSize: typography.fontSizeXSmall,
    titleFontSizeTablet: '0.875rem',
    titleFontWeight: typography.fontWeightBold,
    titleLetterSpacing: '0.0625rem',
    titleBackground: colors.white,
    titleTextTransform: 'uppercase',
    titlePadding: `${spacing.xxSmall} ${spacing.xSmall}`,
    titleOverflowGradientHeight: spacing.xxSmall,
    titleTextDecoration: 'none',
    titleTextDecorationHover: 'underline',
    titleColor: colors.brand,
    ...media
  };
}

generator['canvas-a11y'] = generator['modern-a11y'] = function ({ colors }) {
  return {
    heroTextDecoration: 'underline',
    heroTextDecorationHover: 'none',
    titleColor: colors.licorice,
  };
};

generator.canvas = function (variables) {
  return {
    groupColor: variables["ic-brand-primary"],
    titleColor: variables["ic-brand-primary"]
  };
};
