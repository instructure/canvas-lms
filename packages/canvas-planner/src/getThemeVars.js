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

import {ThemeRegistry} from '@instructure/ui-themeable'
// ^^ at InstUI 8, just directly import getRegistry directly from @instructure/theme-registry
import {merge, cloneDeep} from 'lodash'

// The running theme is the running theme for this page load, and it never
// changes, so there's no point in doing the work more than once.
let memoizedVariables

function getThemeVars() {
  if (memoizedVariables) return memoizedVariables

  const {defaultThemeKey, overrides, themes} = ThemeRegistry.getRegistry()
  // Just assume the "canvas" theme if the default key is null. This will
  // never happen in the live app because one way or another a theme gets
  // used, but unit tests don't always do that.
  // Also we have to cloneDeep this because the merge below is about to
  // mutate the whole thing.
  const variables = cloneDeep(themes[defaultThemeKey ?? 'canvas'].variables)
  merge(variables, overrides)

  memoizedVariables = {variables, key: defaultThemeKey}
  return memoizedVariables
}

export {getThemeVars}
