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

import '@testing-library/jest-dom'
import {vi} from 'vitest'
import $ from 'jquery'

// Import initialization from jest-setup.js that's framework-agnostic
import {loadDevMessages, loadErrorMessages} from '@apollo/client/dev'
import {up as configureDateTime} from '@canvas/datetime/configureDateTime'
import {up as configureDateTimeMomentParser} from '@canvas/datetime/configureDateTimeMomentParser'
import {registerTranslations} from '@canvas/i18n'
import rceFormatMessage from '@instructure/canvas-rce/es/format-message'
import filterUselessConsoleMessages from '@instructure/filter-console-messages'
import CoreTranslations from '../public/javascripts/translations/en.json'
import {up as installNodeDecorations} from './boot/initializers/installNodeDecorations'

// Load Apollo Client dev messages for better error reporting
loadDevMessages()
loadErrorMessages()

// Make jQuery available globally like webpack's ProvidePlugin does
// This is needed for jqueryui plugins to attach to the correct jQuery instance
vi.stubGlobal('$', $)
vi.stubGlobal('jQuery', $)

// Make vi available as jest for compatibility with existing tests
vi.stubGlobal('jest', vi)

// Register translations like jest-setup does
registerTranslations('en', CoreTranslations)

// Configure RCE format-message
rceFormatMessage.setup({
  locale: 'en',
  missingTranslation: 'ignore',
})

// Filter console noise to match Jest behavior
// This helps focus on real errors rather than expected React warnings
const ignoredErrors = [
  /An update to %s inside a test was not wrapped in act/,
  /Can't perform a React state update on an unmounted component/,
  /Function components cannot be given refs/,
  /The above error occurred in the <.*> component/,
  /You seem to have overlapping act\(\) calls/,
  /Warning: `ReactDOMTestUtils.act` is deprecated/,
  /Warning: unmountComponentAtNode is deprecated/,
  /Warning: findDOMNode is deprecated/,
  /Warning: ReactDOM.render is no longer supported in React 18/,
  /Warning: ReactDOMTestUtils is deprecated/,
  /Warning: %s: Support for defaultProps will be removed/,
]
const ignoredWarnings = [
  /JQMIGRATE:/,
  /componentWillReceiveProps/,
  /Found @client directives in a query but no ApolloClient resolvers/,
  /No more mocked responses for the query/,
]
const originalError = console.error
const originalWarn = console.warn
console.error = (msg: unknown, ...args: unknown[]) => {
  const msgStr = String(msg)
  if (ignoredErrors.some(regex => regex.test(msgStr))) return
  if (args.some(arg => ignoredErrors.some(regex => regex.test(String(arg))))) return
  originalError(msg, ...args)
}
console.warn = (msg: unknown, ...args: unknown[]) => {
  if (ignoredWarnings.some(regex => regex.test(String(msg)))) return
  originalWarn(msg, ...args)
}
filterUselessConsoleMessages(console)

vi.stubGlobal('ENV', {
  use_rce_enhancements: true,
  FEATURES: {
    extended_submission_state: true,
  },
})

vi.stubGlobal(
  'IntersectionObserver',
  class IntersectionObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
    takeRecords() {
      return []
    }
  },
)

vi.stubGlobal(
  'ResizeObserver',
  class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  },
)

vi.stubGlobal('DataTransferItem', class DataTransferItem {})

vi.stubGlobal('matchMedia', () => ({
  matches: false,
  addListener() {},
  removeListener() {},
  onchange() {},
  media: '',
}))

vi.stubGlobal(
  'BroadcastChannel',
  vi.fn().mockImplementation(() => ({
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    postMessage: vi.fn(),
    close: vi.fn(),
  })),
)

// Mock performance API - needed for wasPageReloaded.ts
if (!globalThis.performance?.getEntriesByType) {
  vi.stubGlobal('performance', {
    ...globalThis.performance,
    getEntriesByType: vi.fn(() => [{type: 'navigate'}]),
  })
}

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

// Initialize datetime configuration
configureDateTime()
configureDateTimeMomentParser()
installNodeDecorations()

// Window/document polyfills matching jest-setup.js
window.scroll = () => {}
window.scrollTo = () => {}

if (!window.alert) {
  window.alert = () => {}
}

if (!window.HTMLElement.prototype.scrollIntoView) {
  window.HTMLElement.prototype.scrollIntoView = () => {}
}

if (!window.structuredClone) {
  ;(window as unknown as Record<string, unknown>).structuredClone = (obj: unknown) =>
    JSON.parse(JSON.stringify(obj))
}

if (typeof window.URL.createObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'createObjectURL', {value: () => 'http://example.com/whatever'})
}

if (typeof window.URL.revokeObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'revokeObjectURL', {value: () => undefined})
}

if (!Document.prototype.createRange) {
  Document.prototype.createRange = () =>
    ({
      setEnd() {},
      setStart() {},
      getBoundingClientRect() {
        return {right: 0}
      },
      getClientRects() {
        return {length: 0, left: 0, right: 0}
      },
    }) as unknown as Range
}

if (!Range.prototype.getBoundingClientRect) {
  Range.prototype.getBoundingClientRect = () => ({
    bottom: 0,
    height: 0,
    left: 0,
    right: 0,
    top: 0,
    width: 0,
    x: 0,
    y: 0,
    toJSON: () => ({}),
  })
  Range.prototype.getClientRects = () =>
    ({
      item: () => null,
      length: 0,
      [Symbol.iterator]: vi.fn(),
    }) as unknown as DOMRectList
}

// Load InstUI themes
import '@instructure/ui-themes'

// Worker mock
if (!('Worker' in window)) {
  Object.defineProperty(window, 'Worker', {
    value: class Worker {
      postMessage() {}
      terminate() {}
      addEventListener() {}
      removeEventListener() {}
      dispatchEvent() {
        return true
      }
    },
  })
}

// Fetch mock fallback
if (!globalThis.fetch) {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockImplementation(() => Promise.resolve({json: () => ({})})),
  )
}

// Canvas context mock
HTMLCanvasElement.prototype.getContext = vi.fn().mockImplementation(() => ({
  fillRect: vi.fn(),
  clearRect: vi.fn(),
  getImageData: vi.fn().mockReturnValue({
    data: new Array(100),
  }),
  putImageData: vi.fn(),
  createImageData: vi.fn().mockReturnValue([]),
  setTransform: vi.fn(),
  drawImage: vi.fn(),
  save: vi.fn(),
  fillText: vi.fn(),
  restore: vi.fn(),
  beginPath: vi.fn(),
  moveTo: vi.fn(),
  lineTo: vi.fn(),
  closePath: vi.fn(),
  stroke: vi.fn(),
  translate: vi.fn(),
  scale: vi.fn(),
  rotate: vi.fn(),
  arc: vi.fn(),
  fill: vi.fn(),
  measureText: vi.fn().mockReturnValue({width: 0}),
  transform: vi.fn(),
  rect: vi.fn(),
  clip: vi.fn(),
}))
