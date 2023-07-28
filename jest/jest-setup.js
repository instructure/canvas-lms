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

import CoreTranslations from '../public/javascripts/translations/en.json'
import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-16'
import {filterUselessConsoleMessages} from '@instructure/js-utils'
import rceFormatMessage from '@instructure/canvas-rce/lib/format-message'
import {up as configureDateTime} from '../ui/boot/initializers/configureDateTime'
import {up as configureDateTimeMomentParser} from '../ui/boot/initializers/configureDateTimeMomentParser'
import {useTranslations} from '@canvas/i18n'

useTranslations('en', CoreTranslations)

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
/* eslint-disable no-console */
const globalError = global.console.error
const ignoredErrors = [
  /\[object Object\]/,
  /An update to %s inside a test was not wrapped in act/,
  /Can't perform a React state update on an unmounted component/,
  /contextType was defined as an instance property on %s/,
  /Function components cannot be given refs/,
  /Invalid prop `children` supplied to `(Option)`/,
  /Invalid prop `heading` of type `object` supplied to `Billboard`/, // https://instructure.atlassian.net/browse/QUIZ-8870
  /Invariant Violation/,
  /Prop `children` should be supplied unless/, // https://instructure.atlassian.net/browse/FOO-3407
  /The above error occurred in the <.*> component/,
  /You seem to have overlapping act\(\) calls/,
]
const globalWarn = global.console.warn
const ignoredWarnings = [
  /Please update the following components: %s/, // https://instructure.atlassian.net/browse/LS-3906
  /value provided is not in a recognized RFC2822 or ISO format/,
]
global.console = {
  log: console.log,
  error: error => {
    if (ignoredErrors.some(regex => regex.test(error))) {
      return
    }
    globalError(error)
    throw new Error(
      `Looks like you have an unhandled error. Keep our test logs clean by handling or filtering it. ${error}`
    )
  },
  warn: warning => {
    if (ignoredWarnings.some(regex => regex.test(warning))) {
      return
    }
    globalWarn(warning)
    throw new Error(
      `Looks like you have an unhandled warning. Keep our test logs clean by handling or filtering it. ${warning}`
    )
  },
  info: console.info,
  debug: console.debug,
}
/* eslint-enable no-console */
filterUselessConsoleMessages(global.console)

require('jest-fetch-mock').enableFetchMocks()

window.scroll = () => {}
window.ENV = {
  use_rce_enhancements: true,
  FEATURES: {
    extended_submission_state: true,
  },
}

Enzyme.configure({adapter: new Adapter()})

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

configureDateTime()
configureDateTimeMomentParser()

// because everyone implements `flat()` and `flatMap()` except JSDOM 🤦🏼‍♂️
if (!Array.prototype.flat) {
  // eslint-disable-next-line no-extend-native
  Object.defineProperty(Array.prototype, 'flat', {
    configurable: true,
    value: function flat(depth = 1) {
      if (depth === 0) return this.slice()
      return this.reduce(function (acc, cur) {
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
  // eslint-disable-next-line no-extend-native
  Object.defineProperty(Array.prototype, 'flatMap', {
    configurable: true,
    value: function flatMap(_cb) {
      return Array.prototype.map.apply(this, arguments).flat()
    },
    writable: true,
  })
}

require('@instructure/ui-themes')

// set up mocks for native APIs
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

if (!('scrollIntoView' in window.HTMLElement.prototype)) {
  window.HTMLElement.prototype.scrollIntoView = () => {}
}

// Suppress errors for APIs that exist in JSDOM but aren't implemented
Object.defineProperty(window, 'scrollTo', {configurable: true, writable: true, value: () => {}})

const locationProperties = Object.getOwnPropertyDescriptors(window.location)
Object.defineProperty(window, 'location', {
  configurable: true,
  enumerable: true,
  get: () =>
    Object.defineProperties(
      {},
      {
        ...locationProperties,
        href: {
          ...locationProperties.href,
          // Prevents JSDOM errors from doing window.location.href = ...
          set: () => {},
        },
        reload: {
          configurable: true,
          enumerable: true,
          writeable: true,
          // Prevents JSDOM errors from doing window.location.reload()
          value: () => {},
        },
      }
    ),
  // Prevents JSDOM errors from doing window.location = ...
  set: () => {},
})

if (!('structuredClone' in window)) {
  Object.defineProperty(window, 'structuredClone', {
    value: obj => JSON.parse(JSON.stringify(obj)),
  })
}
