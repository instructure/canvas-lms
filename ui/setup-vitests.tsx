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
import {cleanup} from '@testing-library/react'
import {vi, afterEach} from 'vitest'
import $ from 'jquery'

// Track all timers created during tests so we can clean them up
// This prevents memory leaks from InstUI transitions and other timer-based code
const pendingTimeouts = new Set<ReturnType<typeof setTimeout>>()
const pendingIntervals = new Set<ReturnType<typeof setInterval>>()

const originalSetTimeout = globalThis.setTimeout
const originalSetInterval = globalThis.setInterval
const originalClearTimeout = globalThis.clearTimeout
const originalClearInterval = globalThis.clearInterval

// Wrap setTimeout to track pending timers
globalThis.setTimeout = ((callback: (...args: unknown[]) => void, ms?: number, ...args: unknown[]) => {
  const id = originalSetTimeout(() => {
    pendingTimeouts.delete(id)
    callback(...args)
  }, ms)
  pendingTimeouts.add(id)
  return id
}) as typeof setTimeout

// Wrap setInterval to track pending intervals
globalThis.setInterval = ((callback: (...args: unknown[]) => void, ms?: number, ...args: unknown[]) => {
  const id = originalSetInterval(callback, ms, ...args)
  pendingIntervals.add(id)
  return id
}) as typeof setInterval

// Wrap clearTimeout to remove from tracking
globalThis.clearTimeout = ((id?: ReturnType<typeof setTimeout>) => {
  if (id !== undefined) {
    pendingTimeouts.delete(id)
    originalClearTimeout(id)
  }
}) as typeof clearTimeout

// Wrap clearInterval to remove from tracking
globalThis.clearInterval = ((id?: ReturnType<typeof setInterval>) => {
  if (id !== undefined) {
    pendingIntervals.delete(id)
    originalClearInterval(id)
  }
}) as typeof clearInterval

// Global cleanup after each test to prevent memory leaks and timer issues
// This is especially important for InstUI components that use transitions with setTimeout
afterEach(() => {
  // Clear all pending timers from InstUI transitions, animations, etc.
  // These can cause "document is not defined" errors when they fire after jsdom teardown
  for (const id of pendingTimeouts) {
    originalClearTimeout(id)
  }
  pendingTimeouts.clear()

  for (const id of pendingIntervals) {
    originalClearInterval(id)
  }
  pendingIntervals.clear()

  // Clean up any rendered React components that weren't explicitly unmounted
  // This is a safeguard for tests that don't properly clean up
  cleanup()
})

// jQuery plugins (toJSON, dialog, droppable, etc.) are added via the jquery-with-plugins.ts wrapper
// which is aliased in vitest.config.ts. All imports of 'jquery' get the pre-configured instance.

// Mock brandable CSS globally to prevent stylesheet loading errors
// This prevents errors when handlebars templates try to load stylesheets during import
vi.mock('@canvas/brandable-css', () => ({
  __esModule: true,
  default: {
    loadStylesheetForJST: vi.fn(),
    loadStylesheet: vi.fn(),
    getCssVariant: vi.fn(() => 'new_styles_normal_contrast'),
    getHandlebarsIndex: vi.fn(() => [[], {}]),
    urlFor: vi.fn(() => ''),
  },
}))

// Mock grading-scheme module to prevent resolution errors
vi.mock('@canvas/grading-scheme', () => ({
  __esModule: true,
  GradingSchemesSelector: () => null,
  GradingSchemesManagement: () => null,
  UsedLocationsModal: () => null,
}))

// Mock fcUtil to avoid fullCalendar dependency issues in tests
// fullCalendar doesn't properly attach to jQuery in Vitest environment
vi.mock('@canvas/calendar/jquery/fcUtil', async () => {
  const moment = await import('moment')
  const tz = await import('@instructure/moment-utils')

  return {
    default: {
      wrap(date: Date | string | null | undefined) {
        if (!date) return null
        try {
          // fudgeDateForProfileTimezone may not be available, so just use moment directly
          return moment.default(date)
        } catch (e) {
          console.error('Error in fcUtil.wrap:', e)
          return moment.default(date)
        }
      },
      unwrap(date: any) {
        if (!date) return null
        if (date.hasZone && date.hasZone()) {
          return date.toDate()
        } else {
          return tz.parse(date.format())
        }
      },
      now() {
        return moment.default()
      },
      clone(momentObj: any) {
        return moment.default(momentObj)
      },
      addMinuteDelta(momentObj: any, minuteDelta: number) {
        const dayDelta = (minuteDelta / 1440) | 0
        minuteDelta %= 1440
        const result = moment.default(momentObj)
        result.add(dayDelta, 'days')
        result.add(minuteDelta, 'minutes')
        return result
      },
    },
  }
})

// Make jQuery available globally BEFORE importing plugins
// This is needed for jqueryui plugins to attach to the correct jQuery instance
vi.stubGlobal('$', $)
vi.stubGlobal('jQuery', $)

// Make moment available globally for fullCalendar
import moment from 'moment'
vi.stubGlobal('moment', moment)

// Import jqueryui modules in dependency order
// 1. core.js defines $.ui namespace and $.ui.plugin (used by draggable/resizable)
// 2. widget.js defines $.widget() factory used by all other jqueryui modules
// 3. mouse.js defines $.ui.mouse (base for draggable, sortable, etc.)
// 4. Then the rest can be loaded
import 'jqueryui/core'
import 'jqueryui/widget'
import 'jqueryui/mouse'
import 'jqueryui/position'
import 'jqueryui/draggable'
import 'jqueryui/droppable'
import 'jqueryui/resizable'
import 'jqueryui/button'
import 'jqueryui/dialog'
import 'jqueryui/tabs'
import 'jqueryui/sortable'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import 'jqueryui/tooltip'
import 'jqueryui/datepicker'
import 'jqueryui/progressbar'

// jQuery UI plugins are now stubbed in the vi.mock('jquery') factory above
// This ensures ALL imports of jquery get the same instance with plugins attached

// Import Canvas jQuery plugins - these extend $.fn with custom methods
import '@canvas/serialize-form'

// Import Canvas jQuery plugins that extend $ with custom methods
// These are normally loaded via webpack entry points in Jest
import '@canvas/rails-flash-notifications/jquery'

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

// Make vi available as jest for compatibility with existing tests
vi.stubGlobal('jest', vi)

// Add Jest-style skip functions for Vitest compatibility
vi.stubGlobal('xit', vi.fn())
vi.stubGlobal('xdescribe', vi.fn())
vi.stubGlobal('xtest', vi.fn())

// Make mocked() available globally for safe mock casting
// This is equivalent to jest.mocked() / vi.mocked() but works in both runners
// Usage: mocked(myFunction).mockReturnValue('value')
// Instead of: (myFunction as jest.Mock).mockReturnValue('value')
import {mocked} from '@canvas/test-utils/mocked'
vi.stubGlobal('mocked', mocked)

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
  /Consumer uses the legacy contextTypes API/,
  /Warning: ReactDOM.render is no longer supported in React 18/,
]
const ignoredLogs = [
  /JQMIGRATE:/,
]
const originalError = console.error
const originalWarn = console.warn
const originalLog = console.log
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
console.log = (msg: unknown, ...args: unknown[]) => {
  if (ignoredLogs.some(regex => regex.test(String(msg)))) return
  originalLog(msg, ...args)
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

// Fullscreen API mock - needed for media player tests
// jsdom doesn't implement the Fullscreen API
if (!document.fullscreenEnabled) {
  Object.defineProperty(document, 'fullscreenEnabled', {value: true, writable: true, configurable: true})
}
if (!document.fullscreenElement) {
  Object.defineProperty(document, 'fullscreenElement', {value: null, writable: true, configurable: true})
}
if (!document.exitFullscreen) {
  document.exitFullscreen = vi.fn().mockResolvedValue(undefined)
}
if (!HTMLElement.prototype.requestFullscreen) {
  HTMLElement.prototype.requestFullscreen = vi.fn().mockResolvedValue(undefined)
}
// Safari-specific fullscreen API
if (!(document as any).webkitFullscreenEnabled) {
  Object.defineProperty(document, 'webkitFullscreenEnabled', {value: true, writable: true, configurable: true})
}
if (!(HTMLVideoElement.prototype as any).webkitEnterFullscreen) {
  ;(HTMLVideoElement.prototype as any).webkitEnterFullscreen = vi.fn()
}
if (!(HTMLVideoElement.prototype as any).webkitExitFullscreen) {
  ;(HTMLVideoElement.prototype as any).webkitExitFullscreen = vi.fn()
}

if (!window.structuredClone) {
  ;(window as unknown as Record<string, unknown>).structuredClone = (obj: unknown) =>
    JSON.parse(JSON.stringify(obj))
}

if (typeof window.URL.createObjectURL === 'undefined') {
  // Return blob: URLs to match real behavior expected by tests (e.g., FileUpload.test.jsx)
  let blobCounter = 0
  Object.defineProperty(window.URL, 'createObjectURL', {
    value: () => `blob:http://localhost/test-blob-${blobCounter++}`,
  })
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
