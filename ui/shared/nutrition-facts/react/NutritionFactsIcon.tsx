/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {ICON_COLORS} from './constants'

type ColorVariant = 'primary' | 'secondary'

interface NutritionFactsIconProps {
  color?: ColorVariant
  size?: number
}

export const NutritionFactsIcon: React.FC<NutritionFactsIconProps> = ({
  color = 'primary',
  size = 18,
}) => {
  const selectedColor = ICON_COLORS[color]
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 18 18"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      focusable="false"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M9 0C13.9627 0 18 4.0373 18 9C18 13.9627 13.9627 18 9 18C4.0373 18 0 13.9627 0 9C0 4.0373 4.0373 0 9 0ZM9 16.9412C13.3793 16.9412 16.9412 13.3793 16.9412 9C16.9412 4.6207 13.3793 1.05882 9 1.05882C4.6207 1.05882 1.05882 4.6207 1.05882 9C1.05882 13.3793 4.6207 16.9412 9 16.9412Z"
        fill={selectedColor}
      />
      <path
        d="M10.1279 11.1937H8.94975L8.65687 10.202H7.20581L6.90628 11.1937H5.75475L7.25906 6.80062H8.63025L10.1279 11.1937ZM7.41881 9.42319H8.44387L7.93134 7.64597L7.41881 9.42319Z"
        fill={selectedColor}
      />
      <path d="M11.7856 6.80062V11.1937H10.6407V6.80062H11.7856Z" fill={selectedColor} />
    </svg>
  )
}

export default NutritionFactsIcon
