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

import Enzyme from 'enzyme'
import Adapter from 'enzyme-adapter-react-16'

const consoleMessagesToIgnore = {
  error: [
    // /Failed prop type/, // uncomment if you want to focus on stuff besides propType warnings

    'Warning: [Focusable] Exactly one tabbable child is required (0 found).',

    // This is from @instructure/ui-menu, nothing we can do about it ourselves
    /Function components cannot be given refs\. Attempts to access this ref will fail[\s\S]*in (CanvasInstUIModal|PopoverTrigger)/,

  ],
  warn: [
    // /Please update the following components/, // Uncomment this if all the react 16.9 deprecations are cluttering up the console and you want to focus on something else

    // '@instructure/ui-select' itself generates this warning, we assume they will figure it out themselves
    /\[Options\] is experimental and its API could change significantly in a future release[\s\S]*\(created by Selectable\)/,

    // React 16.9+ generates these deprecation warnings but it doesn't do any good to hear about the ones for instUI. We can't do anything about them in this repo
    // Put any others we can't control here.
    /Please update the following components:[ (BaseTransition|Button|Checkbox|CloseButton|Dialog|Expandable|Flex|FlexItem|FormFieldGroup|FormFieldLabel|FormFieldLayout|FormFieldMessages|Grid|GridCol|GridRow|Heading|InlineSVG|Mask|ModalBody|ModalFooter|ModalHeader|NumberInput|Portal|Query|Responsive|SVGIcon|ScreenReaderContent|SelectOptionsList|SelectField|SelectMultiple|SelectOptionsList|SelectSingle|Tab|TabList|TabPanel|Text|TextArea|TextInput|TinyMCE|ToggleDetails|ToggleFacade|Transition|TruncateText|View),?]+$/
  ]
}

Object.keys(consoleMessagesToIgnore).forEach(key => {
  const original = console[key]
  console[key] = function() {
    const combinedMsg = Array.prototype.join.call(arguments)
    const shouldIgnore = pattern => combinedMsg[typeof pattern === 'string' ? 'includes' : 'match'](pattern)
    if (consoleMessagesToIgnore[key].some(shouldIgnore)) return
    return original.apply(this, arguments)
  }
})

global.fetch = require('jest-fetch-mock')

window.scroll = () => {}
window.ENV = {}

Enzyme.configure({ adapter: new Adapter() })

// because InstUI themeable components need an explicit "dir" attribute on the <html> element
document.documentElement.setAttribute('dir', 'ltr')

require('@instructure/ui-themes')

if (process.env.DEPRECATION_SENTRY_DSN) {
  const Raven = require('raven-js')
  Raven.config(process.env.DEPRECATION_SENTRY_DSN, {
    ignoreErrors: ['renderIntoDiv', 'renderSidebarIntoDiv'], // silence the `Cannot read property 'renderIntoDiv' of null` errors we get from the pre- rce_enhancements old rce code
    release: process.env.GIT_COMMIT,
    autoBreadcrumbs: {
      xhr: false
    }
  }).install();

  const setupRavenConsoleLoggingPlugin = require('../app/jsx/shared/helpers/setupRavenConsoleLoggingPlugin').default;
  setupRavenConsoleLoggingPlugin(Raven, { loggerName: 'console-jest' });
}

// set up mocks for native APIs
if (!('MutationObserver' in window)) {
  Object.defineProperty(window, 'MutationObserver', { value: require('@sheerun/mutationobserver-shim') })
}
