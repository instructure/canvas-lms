/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

/**
 * This file defines all the global and component-specific overrides of the default
 * canvas theme that implement the visual differences between K-5 mode and regular
 * canvas. If there is anything that should look universally different when K-5
 * mode is enabled, it should ideally be captured here.
 */
import {
  canvas as canvasBaseTheme,
  canvasHighContrast as canvasHighContrastTheme,
} from '@instructure/ui-themes'
import {mergeDeep} from '@instructure/ui-utils'
import {Day, Grouping, PlannerItem} from '@canvas/planner'

export function getBaseThemeVars() {
  const baseTheme = window.ENV.use_high_contrast ? canvasHighContrastTheme : canvasBaseTheme
  const {variables} = baseTheme
  const {borders, colors, typography} = variables

  /**
   * These are the base defaults used to generate component-specific theme
   * variables in InstUI. For instance, setting the `fontFamily` here will be
   * used as the `fontFamily` value in the `Text` component as well as the
   * `h1FontFamily` value in the `Heading` component.
   */
  const baseFont = {
    typography: {
      fontFamily: ENV.USE_CLASSIC_FONT
        ? typography.fontFamily
        : `"Balsamiq Sans", ${typography.fontFamily}`,
    },
  }
  const base = {
    typography: {
      ...baseFont.typography,
      fontSizeXSmall: '0.875rem',
      fontSizeSmall: '1rem',
      fontSizeMedium: '1.125rem',
      fontSizeLarge: '1.5rem',
      fontSizeXLarge: '2rem',
    },
  }

  return {typography, colors, borders, base, baseTheme, baseFont, variables}
}

/**
 * These are component-specific overrides that only apply to specific InstUI
 * elements. If a component has a separate theme variable that is based off
 * of the default variables or if you only want to change the theme for a
 * single component, it needs to be defined here.
 */
export const getK5ThemeOverrides = () => {
  const {typography, borders, colors} = getK5ThemeVars()
  return {
    Heading: {
      h1FontWeight: typography.fontWeightBold,
      h2FontSize: '1.5rem',
      h2FontWeight: typography.fontWeightBold,
      h3FontSize: '1.25rem',
      h3FontWeight: typography.fontWeightBold,
      h4FontSize: '1.25rem',
      h4FontWeight: typography.fontWeightBold,
      h5FontSize: '1rem',
      h5FontWeight: typography.fontWeightNormal,
    },
    'Tabs.Tab': {
      fontSize: '1.25rem',
    },
    [Grouping.componentId]: {
      borderTopWidth: borders.widthMedium,
      heroPadding: '0.125rem',
    },
    [Day.componentId]: {
      secondaryFontSize: '1rem',
    },
    [PlannerItem.componentId]: {
      iconColor: colors.licorice,
      secondaryColor: colors.licorice,
    },
    'Table.Cell': {
      padding: '1rem 0.75rem',
    },
    IconButton: {
      iconSizeMedium: '1.5rem',
    },
  }
}

/** Overrides applied specifically to resources pages */
export const getResourcesTheme = () => ({
  Heading: {
    h2FontSize: '1.375rem',
    h3FontSize: '1.125rem',
  },
})

// A few overrides for the planner
export const getPlannerTheme = () => {
  const {colors} = getBaseThemeVars()

  return {
    ToggleDetails: {
      iconColor: colors.brand,
      textColor: colors.textBrand,
    },
  }
}

export const useK5Theme = (options = {}) => {
  const {baseTheme, base, baseFont} = getBaseThemeVars()
  const fontOnly = options?.fontOnly || false
  baseTheme.use({overrides: fontOnly ? baseFont : base})
}

export const getK5ThemeVars = () => {
  const {base, variables} = getBaseThemeVars()
  return mergeDeep(variables, base)
}
