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

import '../public/javascripts/translations/_core_en'
import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-16'
import {filterUselessConsoleMessages} from '@instructure/js-utils'
import rceFormatMessage from '@instructure/canvas-rce/lib/format-message'
import plannerFormatMessage from '@instructure/canvas-planner/lib/format-message'
import {up as configureDateTime} from '../ui/boot/initializers/configureDateTime'
import {up as configureDateTimeMomentParser} from '../ui/boot/initializers/configureDateTimeMomentParser'

rceFormatMessage.setup({
  locale: 'en',
  missingTranslation: 'ignore'
})

plannerFormatMessage.setup({
  locale: 'en',
  missingTranslation: 'ignore'
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
  /%s has a method called shouldComponentUpdate/,
  /`NaN` is an invalid value for the `%s` css style property/,
  /<Provider> does not support changing `store` on the fly/,
  /A component is changing a controlled input of type %s to be uncontrolled/,
  /A theme registry has already been initialized/,
  /An update to (%s|DefaultToolForm) inside a test was not wrapped in act/,
  /Can't perform a React state update on an unmounted component/,
  /Cannot read property '(activeElement|useRealTimers)' of undefined/,
  /Cannot read property 'name' of null/,
  /Cannot update during an existing state transition/,
  /ColorPicker: isMounted is deprecated/,
  /contextType was defined as an instance property on %s/,
  /Each child in a list should have a unique "key" prop/,
  /Encountered two children with the same key/,
  /Error writing result to store for query/,
  /Expected one of BreadcrumbLink in Breadcrumb but found 'BreadcrumbLinkWithTip'/,
  /Expected one of Group, Option in Select but found 'option'/,
  /Expected one of ListItem in List but found 'ProfileTab/,
  /Expected one of PaginationButton in Pagination but found .*/,
  /Failed loading the language file for/,
  /Function components cannot be given refs/,
  /Functions are not valid as a React child/,
  /invalid messageType: (notSupported|undefined)/,
  /Invalid prop `children` supplied to `(Option|View)`/,
  /Invalid prop `editorOptions.plugins` of type `string` supplied to `(ForwardRef|RCEWrapper)`/, // https://instructure.atlassian.net/browse/MAT-453
  /Invalid prop `editorOptions.toolbar\[0\]` of type `string` supplied to `(ForwardRef|RCEWrapper)`/, // https://instructure.atlassian.net/browse/MAT-453
  /Invalid prop `heading` of type `object` supplied to `Billboard`/, // https://instructure.atlassian.net/browse/QUIZ-8870
  /Invalid prop `returnFocusTo` of type `DeprecatedComponent` supplied to `(CourseHomeDialog|HomePagePromptContainer)`/,
  /Invalid prop `selectedDate` of type `date` supplied to `CanvasDateInput`/,
  /Invalid prop `value` of type `object` supplied to `CanvasSelect`/,
  /Invariant Violation/,
  /It looks like you're using the wrong act/,
  /Prop `children` should be supplied unless/,
  /props.setRCEOpen is not a function/,
  /React does not recognize the `%s` prop on a DOM element/,
  /Render methods should be a pure function of props and state/,
  /The 'screenReaderOnly' prop must be used in conjunction with 'liveRegion'/,
  /The above error occurred in the <.*> component/,
  /The prop `children` is marked as required in `TruncateText`/,
  /The prop `courseId` is marked as required in `(LatestAnnouncementLink|PublishButton)`/,
  /The prop `currentUserRoles` is marked as required in `ObserverOptions`/,
  /The prop `dateTime` is marked as required in `FriendlyDatetime`/,
  /The prop `focusOnInit` is marked as required in `(FileUpload|TextEntry|UrlEntry)`/,
  /The prop `groupTitle` is marked as required in `(GroupMoveModal|GroupRemoveModal|SearchBreadcrumb)`/,
  /The prop `id` is marked as required in `(CanvasSelectOption|ColHeader|DashboardCard|FormField|Option)`/,
  /The prop `label` is marked as required in `(CanvasInstUIModal|FormField|FormFieldLayout|Modal)`/,
  /The prop `rcsProps.canUploadFiles` is marked as required in `ForwardRef`/,
  /The prop `renderLabel` is marked as required in `(FileDrop|NumberInput|Select)`/,
  /Unexpected keys "searchPermissions", "filterRoles", "tabChanged", "setAndOpenAddTray" found in preloadedState argument passed to createStore/,
  /validateDOMNesting\(...\): %s cannot appear as a child of <%s>/,
  /WARNING: heuristic fragment matching going on!/,
  /Warning: Failed prop type: Expected one of Checkbox in CheckboxGroup but found `View`/,
  /You are using the simple \(heuristic\) fragment matcher, but your queries contain union or interface types./,
  /You seem to have overlapping act\(\) calls/
]
const globalWarn = global.console.warn
const ignoredWarnings = [
  /\[View|Button|Text\] .* in version 8.0.0/i,
  /Error getting \/media_objects\/dummy_media_id\/info/,
  /Exactly one focusable child is required/,
  /Please update the following components: %s/,
  /shared_brand_configs.* not called/,
  /value provided is not in a recognized RFC2822 or ISO format/
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
  debug: console.debug
}
/* eslint-enable no-console */
filterUselessConsoleMessages(global.console)

require('jest-fetch-mock').enableFetchMocks()

window.scroll = () => {}
window.ENV = {
  use_rce_enhancements: true,
  FEATURES: {
    extended_submission_state: true
  }
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
    writable: true
  })
}

if (!Array.prototype.flatMap) {
  // eslint-disable-next-line no-extend-native
  Object.defineProperty(Array.prototype, 'flatMap', {
    configurable: true,
    value: function flatMap(_cb) {
      return Array.prototype.map.apply(this, arguments).flat()
    },
    writable: true
  })
}

require('@instructure/ui-themes')

// set up mocks for native APIs
if (!('MutationObserver' in window)) {
  Object.defineProperty(window, 'MutationObserver', {
    value: require('@sheerun/mutationobserver-shim')
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
    }
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
    }
  })
}

if (!('matchMedia' in window)) {
  window.matchMedia = () => ({
    matches: false,
    addListener: () => {},
    removeListener: () => {}
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
          set: () => {}
        },
        reload: {
          configurable: true,
          enumerable: true,
          writeable: true,
          // Prevents JSDOM errors from doing window.location.reload()
          value: () => {}
        }
      }
    ),
  // Prevents JSDOM errors from doing window.location = ...
  set: () => {}
})
