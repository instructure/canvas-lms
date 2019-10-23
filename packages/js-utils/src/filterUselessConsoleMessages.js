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

const consoleMessagesToIgnore = {
  error: [
    // /Failed prop type/, // uncomment if you want to focus on stuff besides propType warnings

    'Warning: [Focusable] Exactly one tabbable child is required (0 found).',

    // This is from @instructure/ui-menu, nothing we can do about it ourselves
    /Function components cannot be given refs\. Attempts to access this ref will fail[\s\S]*in (CanvasInstUIModal|PopoverTrigger)/
  ],
  warn: [
    // /Please update the following components/, // Uncomment this if all the react 16.9 deprecations are cluttering up the console and you want to focus on something else

    // '@instructure/ui-select' itself generates this warning, we assume they will figure it out themselves
    /is experimental and its API could change significantly in a future release/,
    'Warning: [Focusable] Exactly one focusable child is required (0 found).',

    /in Select \(created by CanvasSelect\)/,

    // React 16.9+ generates these deprecation warnings but it doesn't do any good to hear about the ones for instUI. We can't do anything about them in this repo
    // Put any others we can't control here.
    /Please update the following components:[ (BaseTransition|Billboard|Button|Checkbox|CloseButton|Dialog|Expandable|FileDrop|Flex|FlexItem|FormFieldGroup|FormFieldLabel|FormFieldLayout|FormFieldMessage|FormFieldMessages|Grid|GridCol|GridRow|Heading|InlineSVG|Mask|ModalBody|ModalFooter|ModalHeader|NumberInput|Portal|Query|Responsive|SVGIcon|ScreenReaderContent|SelectOptionsList|SelectField|SelectMultiple|SelectOptionsList|SelectSingle|Spinner|Tab|TabList|TabPanel|Text|TextArea|TextInput|TinyMCE|ToggleDetails|ToggleFacade|Transition|TruncateText|View),?]+$/
  ]
}

export function filterUselessConsoleMessages(orginalConsole = console) {
  Object.keys(consoleMessagesToIgnore).forEach(key => {
    const original = orginalConsole[key]
    orginalConsole[key] = function() {
      const combinedMsg = Array.prototype.join.call(arguments)
      const shouldIgnore = pattern =>
        combinedMsg[typeof pattern === 'string' ? 'includes' : 'match'](pattern)
      if (consoleMessagesToIgnore[key].some(shouldIgnore)) return
      return original.apply(this, arguments)
    }
  })
}
