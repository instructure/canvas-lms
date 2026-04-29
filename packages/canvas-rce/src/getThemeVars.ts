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

const cache = new Map<string, {variables: Record<string, unknown>; key: string}>()

function getThemeVars(useHighContrast = false, fontFamily?: string) {
  const cacheKey = `${useHighContrast}:${fontFamily ?? ''}`
  if (cache.has(cacheKey)) return cache.get(cacheKey)!

  const baseTheme = useHighContrast ? canvasHighContrast : canvas
  const key = useHighContrast ? 'canvas-high-contrast' : 'canvas'

  const brandVars =
    !useHighContrast && typeof window !== 'undefined'
      ? (window as any).CANVAS_ACTIVE_BRAND_VARIABLES || {}
      : {}
  const variables: Record<string, unknown> = {...cloneDeep(baseTheme), ...brandVars}

  if (fontFamily) {
    variables.typography = {...(variables.typography as Record<string, unknown>), fontFamily}
  }

  const result = {variables, key}
  cache.set(cacheKey, result)
  return result
}

export {getThemeVars}
