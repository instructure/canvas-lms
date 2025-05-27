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

import {
  canvasThemeLocal as canvasBaseTheme,
  canvasHighContrastThemeLocal as canvasHighContrastTheme,
} from '@instructure/ui-themes'
import {memoize} from 'lodash'

const EMPTY_OBJ = {}

// Set up the default InstUI theme
// Override the fontFamily to include "Lato Extended", which we prefer
// to load over plain Lato (see LS-1559)
const typography = {
  fontFamily: 'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
}

type BrandVariables = Record<string, unknown>

declare global {
  interface Window {
    CANVAS_ACTIVE_BRAND_VARIABLES?: Record<string, unknown>
  }
}

// either set by argument, ENV.use_high_contrast, or query param
function getIsHighContrastWithFallback(highContrast: unknown) {
  const urlParams = new URLSearchParams(window.location.search)
  const hasHighContrastQueryParam = urlParams.get('instui_theme') === 'canvas_high_contrast'

  const isHighContrast =
    typeof highContrast === 'boolean'
      ? highContrast
      : Boolean(ENV.use_high_contrast || hasHighContrastQueryParam)

  return isHighContrast
}

function getTheme_(highContrast?: unknown, brandVariables?: BrandVariables) {
  const isHighContrast = getIsHighContrastWithFallback(highContrast)
  const brandVariables_ = brandVariables || window.CANVAS_ACTIVE_BRAND_VARIABLES || EMPTY_OBJ

  // Set CSS transitions to 0ms in Selenium and JS tests
  let transitionOverride: {
    transitions?: {
      duration: string
    }
  } = {}
  if (process.env.NODE_ENV === 'test' || window.INST.environment === 'test') {
    transitionOverride = {
      transitions: {
        duration: '0ms',
      },
    }
  }

  return isHighContrast
    ? {
        ...canvasHighContrastTheme,
        typography: {
          ...canvasHighContrastTheme.typography,
          ...typography,
        },
      }
    : {
        ...transitionOverride,
        ...canvasBaseTheme,
        ...brandVariables_,
        typography: {
          ...canvasBaseTheme.typography,
          ...typography,
        },
      }
}
export const getTheme = memoize(getTheme_)
