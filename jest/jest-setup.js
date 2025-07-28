/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {loadDevMessages, loadErrorMessages} from '@apollo/client/dev'
import {up as configureDateTime} from '@canvas/datetime/configureDateTime'
import {up as configureDateTimeMomentParser} from '@canvas/datetime/configureDateTimeMomentParser'
import {registerTranslations} from '@canvas/i18n'
import rceFormatMessage from '@instructure/canvas-rce/es/format-message'
import filterUselessConsoleMessages from '@instructure/filter-console-messages'
import CoreTranslations from '../public/javascripts/translations/en.json'
import {up as installNodeDecorations} from '../ui/boot/initializers/installNodeDecorations'

if (process.env.LOG_PLAYGROUND_URL_ON_FAILURE) {
  process.env.RTL_SKIP_AUTO_CLEANUP = 'true'
}

loadDevMessages()
loadErrorMessages()
registerTranslations('en', CoreTranslations)

rceFormatMessage.setup({
  locale: 'en',
  missingTranslation: 'ignore',
})

/**
 * We want to ensure errors and warnings get appropriate eyes. If
 * you are seeing an exception from here, it probably means you
 * have an unintended consequence from your changes. If you expect
 * the warning/error, add it to the ignore list below.
 */
const globalLog = global.console.log
const globalError = global.console.error
const ignoredLogs = [
  /Migrate is installed with logging active/,
  /Kaltura has not been enabled for this account/,
]
const ignoredErrors = [
  /An update to %s inside a test was not wrapped in act/,
  /Can't perform a React state update on an unmounted component/,
  /Function components cannot be given refs/,
  /Invalid prop `heading` of type `object` supplied to `Billboard`/, // https://instructure.atlassian.net/browse/QUIZ-8870
  /Invariant Violation/, // https://instructure.atlassian.net/browse/VICE-3968
  /Prop `children` should be supplied unless/, // https://instructure.atlassian.net/browse/FOO-3407
  /The above error occurred in the <.*> component/,
  /You seem to have overlapping act\(\) calls/,
  /Warning: `value` prop on `%s` should not be null. Consider using an empty string to clear the component or `undefined` for uncontrolled components.%s/,
  /Invalid prop `color` of value `secondary` supplied to `CondensedButton`, expected one of \["primary","primary-inverse"\]./,
  /Warning: This synthetic event is reused for performance reasons/,
  /Invalid prop `value` supplied to `MenuItem`/, // https://instructure.atlassian.net/browse/INSTUI-4054
  /Warning: %s: Support for defaultProps will be removed from function components in a future major release. Use JavaScript default parameters instead.%s/,
  /Warning: `ReactDOMTestUtils.act` is deprecated in favor of `React.act`. Import `act` from `react` instead of `react-dom\/test-utils`./,
  /Warning: unmountComponentAtNode is deprecated and will be removed in the next major release. Switch to the createRoot API. Learn more: https:\/\/reactjs.org\/link\/switch-to-createroot/,
  /Warning: findDOMNode is deprecated and will be removed in the next major release. Instead, add a ref directly to the element you want to reference./,
  /Warning: %s uses the legacy childContextTypes API which is no longer supported and will be removed in the next major release. Use React.createContext\(\) instead/,
  /Warning: %s uses the legacy contextTypes API which is no longer supported and will be removed in the next major release. Use React.createContext\(\) with static contextType instead./,
  /Warning: Component "%s" contains the string ref "%s". Support for string refs will be removed in a future major release. We recommend using useRef\(\) or createRef\(\) instead. Learn more about using refs safely here:/,
  /Warning: ReactDOMTestUtils is deprecated and will be removed in a future major release, because it exposes internal implementation details that are highly likely to change between releases. Upgrade to a modern testing library/,
  /Warning: %s: Support for defaultProps will be removed from memo components in a future major release. Use JavaScript default parameters instead./,
  /Warning: Component "%s" contains the string ref "%s". Support for string refs will be removed in a future major release. We recommend using useRef\(\) or createRef\(\) instead. Learn more about using refs safely here: https:\/\/reactjs.org\/link\/strict-mode-string-ref/,
]
const globalWarn = global.console.warn
const ignoredWarnings = [
  /JQMIGRATE:/, // ignore warnings about jquery migrate; these are muted globally when not in a jest test
  /componentWillReceiveProps/, // ignore warnings about componentWillReceiveProps; this method is deprecated and will be removed with react upgrades
  /Found @client directives in a query but no ApolloClient resolvers were specified/, // ignore warnings about missing ApolloClient resolvers
  /No more mocked responses for the query/, // https://github.com/apollographql/apollo-client/pull/10502
]

global.console = {
  log: (log, ...rest) => {
    if (ignoredLogs.some(regex => regex.test(log))) {
      return
    }
    globalLog(log, ...rest)
  },
  error: (error, ...rest) => {
    if (
      ignoredErrors.some(regex => regex.test(error)) ||
      ignoredErrors.some(regex => regex.test(rest))
    ) {
      return
    }
    globalError(error, rest)
  },
  warn: (warning, ...rest) => {
    if (ignoredWarnings.some(regex => regex.test(warning))) {
      return
    }
    globalWarn(warning, rest)
  },
  info: console.info,
  debug: console.debug,
}
filterUselessConsoleMessages(global.console)

window.scroll = () => {}
window.ENV = {
  use_rce_enhancements: true,
  FEATURES: {
    extended_submission_state: true,
  },
}

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

configureDateTime()
configureDateTimeMomentParser()
installNodeDecorations()

// because everyone implements `flat()` and `flatMap()` except JSDOM 🤦🏼‍♂️
if (!Array.prototype.flat) {
  Object.defineProperty(Array.prototype, 'flat', {
    configurable: true,
    value: function flat(depth = 1) {
      if (depth === 0) return this.slice()
      return this.reduce((acc, cur) => {
        if (Array.isArray(cur)) {
          acc.push(...flat.call(cur, depth - 1))
        } else {
          acc.push(cur)
        }
        return acc
      }, [])
    },
    writable: true,
  })
}

if (!Array.prototype.flatMap) {
  Object.defineProperty(Array.prototype, 'flatMap', {
    configurable: true,
    value: function flatMap(_cb) {
      // biome-ignore lint/style/noArguments: <explanation>
      return Array.prototype.map.apply(this, arguments).flat()
    },
    writable: true,
  })
}

if (!Set.prototype.isDisjointFrom) {
  Object.defineProperty(Set.prototype, 'isDisjointFrom', {
    configurable: true,
    value: function isDisjointFrom(otherSet) {
      return Array.from(this).every(value => !otherSet.has(value))
    },
    writable: true,
  })
}

require('@instructure/ui-themes')

// set up mocks for native APIs
if (!('alert' in window)) {
  window.alert = () => {}
}

if (!('MutationObserver' in window)) {
  Object.defineProperty(window, 'MutationObserver', {
    value: require('@sheerun/mutationobserver-shim'),
  })
}

if (!('IntersectionObserver' in window)) {
  Object.defineProperty(window, 'IntersectionObserver', {
    writable: true,
    configurable: true,
    value: class IntersectionObserver {
      disconnect() {
        return null
      }

      observe() {
        return null
      }

      takeRecords() {
        return null
      }

      unobserve() {
        return null
      }
    },
  })
}

if (!('ResizeObserver' in window)) {
  Object.defineProperty(window, 'ResizeObserver', {
    writable: true,
    configurable: true,
    value: class IntersectionObserver {
      observe() {
        return null
      }

      unobserve() {
        return null
      }

      disconnect() {
        return null
      }
    },
  })
}

if (!('matchMedia' in window)) {
  window.matchMedia = () => ({
    matches: false,
    addListener: () => {},
    removeListener: () => {},
  })
  window.matchMedia._mocked = true
}

global.BroadcastChannel = jest.fn().mockImplementation(() => ({
  addEventListener: jest.fn(),
  removeEventListener: jest.fn(),
  postMessage: jest.fn(),
  close: jest.fn(),
}))

global.DataTransferItem = global.DataTransferItem || class DataTransferItem {}

global.performance = global.performance || {}
global.performance.getEntriesByType = global.performance.getEntriesByType || (() => [])

if (!('scrollIntoView' in window.HTMLElement.prototype)) {
  window.HTMLElement.prototype.scrollIntoView = () => {}
}

// Suppress errors for APIs that exist in JSDOM but aren't implemented
Object.defineProperty(window, 'scrollTo', {
  configurable: true,
  writable: true,
  value: () => {},
})

if (!('structuredClone' in window)) {
  Object.defineProperty(window, 'structuredClone', {
    value: obj => JSON.parse(JSON.stringify(obj)),
  })
}

if (typeof window.URL.createObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'createObjectURL', {value: () => 'http://example.com/whatever'})
}

// Mock localStorage if it's not available in the test environment
if (!('localStorage' in window)) {
  class LocalStorageMock {
    constructor() {
      this.store = {}
      this.length = 0
    }

    updateLength() {
      this.length = Object.keys(this.store).length
    }

    clear() {
      this.store = {}
      this.updateLength()
    }

    getItem(key) {
      return this.store[key] || null
    }

    setItem(key, value) {
      this.store[key] = String(value)
      this.updateLength()
    }

    removeItem(key) {
      delete this.store[key]
      this.updateLength()
    }

    key(index) {
      const keys = Object.keys(this.store)
      return index >= 0 && index < keys.length ? keys[index] : null
    }
  }

  Object.defineProperty(window, 'localStorage', {
    value: new LocalStorageMock(),
    writable: true,
  })
}

if (typeof window.URL.revokeObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'revokeObjectURL', {value: () => undefined})
}

global.fetch =
  global.fetch || jest.fn().mockImplementation(() => Promise.resolve({json: () => ({})}))

Document.prototype.createRange =
  Document.prototype.createRange ||
  (() => ({
    setEnd() {},
    setStart() {},
    getBoundingClientRect() {
      return {right: 0}
    },
    getClientRects() {
      return {
        length: 0,
        left: 0,
        right: 0,
      }
    },
  }))

if (!('Worker' in window)) {
  Object.defineProperty(window, 'Worker', {
    value: class Worker {
      constructor() {
        this.postMessage = () => {}
        this.terminate = () => {}
        this.addEventListener = () => {}
        this.removeEventListener = () => {}
        this.dispatchEvent = () => {}
      }
    },
  })
}

if (!Range.prototype.getBoundingClientRect) {
  Range.prototype.getBoundingClientRect = () => ({
    bottom: 0,
    height: 0,
    left: 0,
    right: 0,
    top: 0,
    width: 0,
  })
  Range.prototype.getClientRects = () => ({
    item: () => null,
    length: 0,
    [Symbol.iterator]: jest.fn(),
  })
}
