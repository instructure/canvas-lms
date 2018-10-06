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
export default function generator ({ borders, colors, spacing, typography }) {
  return {
    padding: `${spacing.xSmall} ${spacing.small} ${spacing.small}`,
    borderBottom: `${borders.widthSmall} ${borders.style} ${colors.tiara}`,
    borderColor: colors.tiara,
    borderWidth: borders.widthSmall,
    borderStyle: borders.style,
    itemMargin: spacing.small,
    itemPadding: spacing.xxSmall,
    lineHeight: typography.lineHeightCondensed,
  };
}
