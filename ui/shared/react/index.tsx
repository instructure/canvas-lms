/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import {
  canvas as canvasBaseTheme,
  canvasHighContrast as canvasHighContrastTheme,
} from '@instructure/ui-themes'
import {InstUISettingsProvider} from '@instructure/emotion'
import {memoize} from 'lodash'

// Set up the default InstUI theme
// Override the fontFamily to include "Lato Extended", which we prefer
// to load over plain Lato (see LS-1559)
const typography = {
  fontFamily: 'LatoWeb, "Lato Extended", Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
}

const EMPTY_OBJ = {}

type BrandVariables = Record<string, unknown>

type Options = {
  highContrast?: boolean
  brandVariables?: Record<string, unknown>
}

function getTheme(highContrast: boolean, brandVariables: BrandVariables) {
  // Set CSS transitions to 0ms in Selenium and JS tests
  let transitionOverride: {
    transitions?: {
      duration: string
    }
  } = {}
  // @ts-expect-error
  if (process.env.NODE_ENV === 'test' || window.INST.environment === 'test') {
    transitionOverride = {
      transitions: {
        duration: '0ms',
      },
    }
  }

  return highContrast
    ? {
        ...canvasHighContrastTheme,
        typography,
      }
    : {
        ...transitionOverride,
        ...canvasBaseTheme,
        ...brandVariables,
        typography,
      }
}
const memoizedGetTheme = memoize(getTheme)

export function render(
  element: React.ReactElement,
  container: Element | null,
  options: Options = {}
) {
  if (!(container instanceof HTMLElement)) {
    throw new Error('Container must be an HTMLElement')
  }
  const highContrast =
    typeof options.highContrast === 'boolean'
      ? options.highContrast
      : // @ts-expect-error
        Boolean(ENV.use_high_contrast)

  // @ts-expect-error
  const brandVariables = options.brandVariables || window.CANVAS_ACTIVE_BRAND_VARIABLES || EMPTY_OBJ

  const theme = memoizedGetTheme(highContrast, brandVariables)

  const root = createRoot(container)
  root.render(<InstUISettingsProvider theme={theme}>{element}</InstUISettingsProvider>)
  return root
}
