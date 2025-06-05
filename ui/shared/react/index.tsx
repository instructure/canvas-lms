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
import ReactDOM from 'react-dom'
import {getTheme} from '@canvas/instui-bindings'
import {DynamicInstUISettingsProvider} from '@canvas/instui-bindings/react/DynamicInstUISettingProvider'

type Options = {
  highContrast?: boolean
  brandVariables?: Record<string, unknown>
}

export function legacyRender(
  element: React.ReactElement,
  container: Element | null,
  options: Options = {},
) {
  if (!(container instanceof HTMLElement)) {
    throw new Error('Container must be an HTMLElement')
  }

  const theme = getTheme(options.highContrast, options.brandVariables)

  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(
    <DynamicInstUISettingsProvider theme={theme}>{element}</DynamicInstUISettingsProvider>,
    container,
  )
}

export function render(
  element: React.ReactElement,
  container: Element | null,
  options: Options = {},
) {
  if (!(container instanceof HTMLElement)) {
    throw new Error('Container must be an HTMLElement')
  }

  const theme = getTheme(options.highContrast, options.brandVariables)

  const root = createRoot(container)
  root.render(
    <DynamicInstUISettingsProvider theme={theme}>{element}</DynamicInstUISettingsProvider>,
  )
  return root
}
