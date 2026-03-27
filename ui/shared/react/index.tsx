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
import ReactDOM, {flushSync} from 'react-dom'
import {getTheme} from '@canvas/instui-bindings'
import {DynamicInstUISettingsProvider} from '@canvas/instui-bindings/react/DynamicInstUISettingProvider'

type Options = {
  highContrast?: boolean
  brandVariables?: Record<string, unknown>
  sync?: boolean
}

let _cachedTheme: ReturnType<typeof getTheme> | null = null
let _cachedKey: string | null = null

function getStableTheme(options: Options) {
  const key = `${options.highContrast}|${ENV.K5_USER}|${ENV.USE_CLASSIC_FONT}|${ENV.use_dyslexic_font}|${options.brandVariables ? JSON.stringify(options.brandVariables) : ''}`
  if (key !== _cachedKey) {
    _cachedKey = key
    _cachedTheme = getTheme(
      options.highContrast,
      options.brandVariables,
      Boolean(ENV.K5_USER),
      Boolean(ENV.USE_CLASSIC_FONT),
      Boolean(ENV.use_dyslexic_font),
    )
  }
  return _cachedTheme!
}

export function legacyRender(
  element: React.ReactElement,
  container: Element | null,
  options: Options = {},
) {
  // Use nodeType check instead of instanceof to support cross-frame elements
  // (e.g. window.parent.document.getElementById from inside an iframe)
  if (!container || container.nodeType !== 1) {
    throw new Error('Container must be an HTMLElement')
  }

  const theme = getStableTheme(options)

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
  if (!container || container.nodeType !== 1) {
    throw new Error('Container must be an HTMLElement')
  }

  const theme = getStableTheme(options)
  const wrapped = (
    <DynamicInstUISettingsProvider theme={theme}>{element}</DynamicInstUISettingsProvider>
  )

  const root = createRoot(container)
  if (options.sync) flushSync(() => root.render(wrapped))
  else root.render(wrapped)
  return root
}

export function rerender(
  root: ReturnType<typeof createRoot>,
  element: React.ReactElement,
  options: Options = {},
) {
  const theme = getStableTheme(options)
  const wrapped = (
    <DynamicInstUISettingsProvider theme={theme}>{element}</DynamicInstUISettingsProvider>
  )

  if (options.sync) flushSync(() => root.render(wrapped))
  else root.render(wrapped)
}

export function legacyUnmountComponentAtNode(container: Element | null) {
  if (!container || container.nodeType !== 1) {
    return false
  }
  return ReactDOM.unmountComponentAtNode(container)
}
