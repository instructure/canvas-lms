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
export default function generator ({ borders, colors, spacing, typography }) {
  return {
    fontFamily: typography.fontFamily,
    lineHeight: typography.lineHeightCondensed,
    color: colors.licorice,

    padding: `${spacing.small} ${spacing.xSmall}`,
    paddingMedium: `${spacing.small}`,
    paddingLarge: `${spacing.small} ${spacing.medium}`,

    gutterWidth: spacing.medium,
    gutterWidthXLarge: spacing.medium,

    bottomMargin: spacing.xSmall,

    borderWidth: borders.widthSmall,
    borderColor: colors.tiara,

    iconFontSize: spacing.medium,
    iconColor: colors.brand,
    badgeMargin: '0.0625rem',

    metricsPadding: spacing.xxSmall,

    typeMargin: spacing.xxxSmall,

    titleLineHeight: typography.lineHeightFit,
  };
}

generator.canvas = function (variables) {
  return {
    iconColor: variables["ic-brand-primary"],
  };
};
