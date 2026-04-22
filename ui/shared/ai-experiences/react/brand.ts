/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

// Brand gradient colors
export const BRAND_PURPLE = '#7959AF'
export const BRAND_TEAL = '#207796'
export const BRAND_GRADIENT = `linear-gradient(to right, ${BRAND_PURPLE}, ${BRAND_TEAL})`

// Dark navy — used for primary action buttons
export const NAVY = 'rgb(39, 53, 64)'
export const NAVY_HOVER = 'rgb(30, 42, 52)'
export const NAVY_ACTIVE = 'rgb(25, 35, 43)'

// Success green — used for the published state button
export const GREEN = '#03893D'
export const GREEN_HOVER = '#026f30'
export const GREEN_ACTIVE = '#025c28'

// Pure black — used for progress bar border
export const BLACK = '#000000'

// Border radii
export const RADIUS_SM = '0.5rem' // buttons, inputs
export const RADIUS_MD = '0.75rem' // cards
export const RADIUS_LG = '1.5rem' // large cards
export const RADIUS_PILL = '999px' // pill / fully-rounded

// Reusable InstUI themeOverride: any button that only needs rounded corners (secondary/outline)
export const buttonTheme = {borderRadius: RADIUS_SM}

// Reusable InstUI themeOverride: published (green) button
export const publishedButtonTheme = {
  borderRadius: RADIUS_SM,
  primaryBackground: GREEN,
  primaryHoverBackground: GREEN_HOVER,
  primaryActiveBackground: GREEN_ACTIVE,
  primaryBorderColor: GREEN,
}

// Reusable InstUI themeOverride: navy filled button
export const navyButtonTheme = {
  borderRadius: RADIUS_SM,
  primaryBackground: NAVY,
  primaryHoverBackground: NAVY_HOVER,
  primaryActiveBackground: NAVY_ACTIVE,
  primaryBorderColor: NAVY,
}

// Reusable InstUI themeOverride: navy pill button (vote buttons)
export const navyPillButtonTheme = {
  borderRadius: RADIUS_PILL,
  primaryBackground: NAVY,
  primaryHoverBackground: NAVY_HOVER,
  primaryActiveBackground: NAVY_ACTIVE,
  primaryBorderColor: NAVY,
}

// Reusable InstUISettingsProvider theme: rounded corners
export const roundedTheme = {
  componentOverrides: {
    View: {borderRadiusMedium: RADIUS_MD, borderRadiusLarge: RADIUS_LG},
    BaseButton: {borderRadius: RADIUS_SM},
    TextArea: {borderRadius: RADIUS_SM},
  },
}
