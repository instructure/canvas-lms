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

export interface WidgetColors {
  pageBackground: string
  cardBackground: string
  cardSecondary: string
  border: string
  textPrimary: string
  textSecondary: string
  textLink: string
  inputBackground: string
  inputBorder: string
}

export const lightColors: WidgetColors = {
  pageBackground: '#FFFFFF',
  cardBackground: '#FFFFFF',
  cardSecondary: '#F9FAFA',
  border: '#E8EAEC',
  textPrimary: '#273540',
  textSecondary: '#586874',
  textLink: '#0E68B3',
  inputBackground: '#FFFFFF',
  inputBorder: '#9EA6AD',
}

export const darkColors: WidgetColors = {
  pageBackground: '#1B2330',
  cardBackground: '#1F2D3D',
  cardSecondary: '#253443',
  border: '#2E3E4E',
  textPrimary: '#FFFFFF',
  textSecondary: '#9EA6AD',
  textLink: '#5A9FD4',
  inputBackground: '#253443',
  inputBorder: '#4A5B68',
}

export function getWidgetColors(isDark: boolean): WidgetColors {
  return isDark ? darkColors : lightColors
}
