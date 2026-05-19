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

import {InstUISettingsProvider} from '@instructure/emotion'
import type {ThemeOrOverride} from '@instructure/emotion/types/EmotionTypes'
import {getTheme, loadCareerTheme} from '@instructure/platform-instui-bindings'
import React, {useEffect, useState} from 'react'
import {createRoot} from 'react-dom/client'
import ReactDOM, {flushSync} from 'react-dom'

type Options = {
  highContrast?: boolean
  brandVariables?: Record<string, unknown>
  sync?: boolean
}

let _cachedTheme: ThemeOrOverride | null = null
let _cachedKey: string | null = null

declare global {
  interface Window {
    CANVAS_ACTIVE_BRAND_VARIABLES?: Record<string, unknown>
  }
}

function getStableTheme(options: Options = {}): ThemeOrOverride {
  const brandVariables = options.brandVariables ?? window.CANVAS_ACTIVE_BRAND_VARIABLES ?? undefined
  const key = `${options.highContrast}|${ENV.K5_USER}|${ENV.USE_CLASSIC_FONT}|${ENV.use_dyslexic_font}|${brandVariables ? JSON.stringify(brandVariables) : ''}`
  if (key !== _cachedKey) {
    _cachedKey = key
    const theme = getTheme({
      highContrast: Boolean(options.highContrast),
      brandVariables,
      k5User: Boolean(ENV.K5_USER),
      useClassicFont: Boolean(ENV.USE_CLASSIC_FONT),
      useDyslexicFont: Boolean(ENV.use_dyslexic_font),
    })
    // Platform's getTheme only zeros transitions when NODE_ENV === 'test'.
    // Selenium runs with NODE_ENV !== 'test' but sets window.INST.environment;
    // without this, modal animations cause flaky click-intercepted failures.
    _cachedTheme =
      window.INST?.environment === 'test' ? {...theme, transitions: {duration: '0ms'}} : theme
  }
  return _cachedTheme as ThemeOrOverride
}

/**
 * Returns the currently active, cached canvas theme. Use this to pass `theme`
 * into headless dialog utilities from @instructure/platform-instui-bindings
 * (confirm/alert/etc.), which mount in a detached portal outside the InstUI
 * provider tree.
 */
export function getActiveCanvasTheme(): ThemeOrOverride {
  return getStableTheme()
}

type CanvasThemeProviderProps = {
  theme: ThemeOrOverride
  children: React.ReactNode
}

/**
 * Wraps children in InstUISettingsProvider and applies the career theme
 * override when the `instui_theme` URL param is `career` or `career-dark`.
 * Drop-in replacement for the old canvas-local
 * DynamicInstUISettingsProvider.
 */
export const CanvasThemeProvider = ({theme: initialTheme, children}: CanvasThemeProviderProps) => {
  const [theme, setTheme] = useState<ThemeOrOverride>(initialTheme)
  const urlParams = new URLSearchParams(window.location.search)
  const themeParam = urlParams.get('instui_theme')
  const isCareerDark = themeParam === 'career-dark'
  const isCareerTheme = themeParam === 'career' || isCareerDark

  useEffect(() => {
    if (isCareerTheme) {
      loadCareerTheme({
        themeUrl: isCareerDark ? window.ENV.CAREER_DARK_THEME_URL : window.ENV.CAREER_THEME_URL,
        fallbackUrl: isCareerDark ? (window.ENV.CAREER_THEME_URL ?? undefined) : undefined,
      }).then(loadedTheme => {
        if (loadedTheme) {
          setTheme(loadedTheme)
        }
      })
    }
  }, [isCareerTheme, isCareerDark])

  return <InstUISettingsProvider theme={theme}>{children}</InstUISettingsProvider>
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
    <CanvasThemeProvider theme={theme}>{element}</CanvasThemeProvider>,
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
  const wrapped = <CanvasThemeProvider theme={theme}>{element}</CanvasThemeProvider>

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
  const wrapped = <CanvasThemeProvider theme={theme}>{element}</CanvasThemeProvider>

  if (options.sync) flushSync(() => root.render(wrapped))
  else root.render(wrapped)
}

export function legacyUnmountComponentAtNode(container: Element | null) {
  if (!container || container.nodeType !== 1) {
    return false
  }
  return ReactDOM.unmountComponentAtNode(container)
}
