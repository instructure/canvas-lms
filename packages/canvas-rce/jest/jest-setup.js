/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// Several components use aphrodite, which tries to manipulate the dom
// on a timer which expires after the test completes and the document no longer exists
import {StyleSheetTestUtils} from 'aphrodite'
// eslint-disable-next-line import/no-nodejs-modules
import {TextDecoder, TextEncoder} from 'util'

global.TextEncoder = TextEncoder
global.TextDecoder = TextDecoder

/**
 * We want to ensure errors and warnings get appropriate eyes. If
 * you are seeing an exception from here, it probably means you
 * have an unintended consequence from your changes. If you expect
 * the warning/error, add it to the ignore list below.
 */
/* eslint-disable no-console */
const globalError = global.console.error
const ignoredErrors = [
  /An update to %s inside a test was not wrapped in act/,
  /Can't perform a React state update on an unmounted component/,
  /The prop `sortBy.order` is marked as required in `Images`/,
  /Invalid prop `documents.searchString` of type `string` supplied to `DocumentsPanel`/,
  /The prop `sortBy.order` is marked as required in `DocumentsPanel`/,
  /The prop `sortBy.order` is marked as required in `SavedIconMakerList`/,
  /Invalid prop `images.searchString` of type `string` supplied to `SavedIconMakerList`/,
  /Invalid prop `media.searchString` of type `string` supplied to `MediaPanel`/,
  /Can't call %s on a component that is not yet mounted./,
  /The prop `videoOptions.naturalHeight` is marked as required in `VideoOptionsTray`/,
  /The prop `sortBy.order` is marked as required in `MediaPanel`/,
  /Invalid prop `images.searchString` of type `string` supplied to `Images`/,
  /failed updating video captions/,
  /You seem to have overlapping act\(\) calls/,
  /A theme registry has already been initialized/,
  /Warning: Failed prop type: Invalid prop `color` of value `secondary` supplied to `CondensedButton`, expected one of \["primary","primary-inverse"\]./,
  /ReactDOM.render is no longer supported in React 18/,
  /Warning: Failed %s type: %s%s/,
  /Warning: %s: Support for defaultProps will be removed from function components in a future major release. Use JavaScript default parameters instead.%s/,
  /Warning: `ReactDOMTestUtils.act` is deprecated in favor of `React.act`. Import `act` from `react` instead of `react-dom\/test-utils`. See https:\/\/react.dev\/warnings\/react-dom-test-utils for more info./,
  /Warning: `ReactDOMTestUtils.act` is deprecated in favor of `React.act`. Import `act` from `react` instead of `react-dom\/test-utils`./,
  /Warning: unmountComponentAtNode is deprecated and will be removed in the next major release. Switch to the createRoot API. Learn more: https:\/\/reactjs.org\/link\/switch-to-createroot/,
  /Warning: findDOMNode is deprecated and will be removed in the next major release. Instead, add a ref directly to the element you want to reference. Learn more about using refs safely here: https:\/\/reactjs.org\/link\/strict-mode-find-node/,
  /Warning: %s uses the legacy childContextTypes API which is no longer supported and will be removed in the next major release. Use React.createContext\(\) instead/,
  /Warning: %s uses the legacy contextTypes API which is no longer supported and will be removed in the next major release. Use React.createContext\(\) with static contextType instead./,
  /Warning: Unknown event handler property `%s`. It will be ignored.%s/,
]
const globalWarn = global.console.warn
const ignoredWarnings = [
  /Store interaction failed/,
  /Found bad LTI MRU data/,
  /Cannot save LTI MRU list/,
  /clicked sidebar (link|image) without a focused editor/,
  /Translation for/,
  /Exactly one focusable child is required/,
  /is deprecated and will be removed/,
]
global.console = {
  log: console.log,
  error: error => {
    if (ignoredErrors.some(regex => regex.test(error))) {
      return
    }
    globalError(error)
    throw new Error(
      `Looks like you have an unhandled error. Keep our test logs clean by handling or filtering it. ${error}`,
    )
  },
  warn: warning => {
    if (ignoredWarnings.some(regex => regex.test(warning))) {
      return
    }
    globalWarn(warning)
    throw new Error(
      `Looks like you have an unhandled warning. Keep our test logs clean by handling or filtering it. ${warning}`,
    )
  },
  info: console.info,
  debug: console.debug,
}
/* eslint-enable no-console */

StyleSheetTestUtils.suppressStyleInjection()

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

require('@instructure/ui-themes')

// set up mocks for native APIs
if (!('MutationObserver' in window)) {
  Object.defineProperty(window, 'MutationObserver', {
    value: require('@sheerun/mutationobserver-shim'),
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

if (typeof window.URL.createObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'createObjectURL', {value: () => 'http://example.com/whatever'})
}

global.DataTransferItem = global.DataTransferItem || class DataTransferItem {}

window.scroll = () => {}
