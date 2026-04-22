/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {canvas, canvasHighContrast} from '@instructure/ui-themes'
import {cloneDeep} from 'es-toolkit/compat'
import {getTypography} from '@canvas/instui-bindings'

// In case we are running a test and there is absolutely no theme data available
// (happens often)
const fallback = {
  typography: {},
  colors: {},
  spacing: {},
  borders: {},
}

// The running theme is the running theme for this page load, and it never
// changes, so there's no point in doing the work more than once.
let memoizedVariables

function getThemeVars() {
  if (memoizedVariables) return memoizedVariables

  const useHighContrast = typeof window !== 'undefined' && window.ENV?.use_high_contrast
  const themeKey = useHighContrast ? 'canvas-high-contrast' : 'canvas'
  const theme = useHighContrast ? canvasHighContrast : canvas
  const brandVars =
    !useHighContrast && typeof window !== 'undefined'
      ? window.CANVAS_ACTIVE_BRAND_VARIABLES || {}
      : {}
  const variables = {...cloneDeep(theme || fallback), ...brandVars}
  variables.typography = {
    ...variables.typography,
    ...getTypography(
      Boolean(ENV.K5_USER),
      Boolean(ENV.USE_CLASSIC_FONT),
      Boolean(ENV.use_dyslexic_font),
    ),
  }

  memoizedVariables = {variables, key: themeKey}
  return memoizedVariables
}

export {getThemeVars}
