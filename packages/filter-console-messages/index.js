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

    'Support for defaultProps will be removed from function components in a future major release.',

    // Remove when we've converted all ReactDOM.render to createRoot
    "Warning: ReactDOM.render is no longer supported in React 18. Use createRoot instead. Until you switch to the new API, your app will behave as if it's running React 17. Learn more: https://reactjs.org/link/switch-to-createroot",

    // This is from @instructure/ui-menu, nothing we can do about it ourselves
    /Function components cannot be given refs\. Atte˚qπmpts to access this ref will fail[\s\S]*in (CanvasInstUIModal|PopoverTrigger)/,
    /.*A theme registry has already been initialized.*/,
    // from an old discussions edit page
    /Error: Not implemented: navigation \(except hash changes\)/,
    /unknown pseudo-class selector/,

    /uses the legacy childContextTypes API which is no longer supported/,
    /findDOMNode is deprecated/,

    // React 18 act() warnings for Popup component that creates its own roots
    /Warning: The current testing environment is not configured to support act\(\.\.\.\)/,
    /Warning: Attempted to synchronously unmount a root while React was already rendering/,
  ],
  warn: [
    // Uncomment the following line if all the react 16.9 deprecations are cluttering up
    // the console and you want to focus on something else
    // /Please update the following components/,

    // The build logs have grown to over 250MB so in an interest of being able to use
    // the build logs at all we're filtering out these general messages.
    /is deprecated and will be removed/,
    /Translation for/,

    // '@instructure/ui-select' itself generates this warning, we assume they will figure it out themselves
    /is experimental and its API could change significantly in a future release/,
    'Warning: [Focusable] Exactly one focusable child is required (0 found).',

    /in Select \(created by CanvasSelect\)/,
    'created by DateInput',
    'created by Editable',

    // React 16.9+ generates these deprecation warnings but it doesn't do any good to hear about the ones for instUI. We can't do anything about them in this repo
    // Put any others we can't control here.
    /Please update the following components:[ (BaseTransition|Billboard|Button|Checkbox|CloseButton|Dialog|Expandable|FileDrop|Flex|FlexItem|FormFieldGroup|FormFieldLabel|FormFieldLayout|FormFieldMessage|FormFieldMessages|Grid|GridCol|GridRow|Heading|InlineSVG|Mask|ModalBody|ModalFooter|ModalHeader|NumberInput|Portal|Query|Responsive|SVGIcon|ScreenReaderContent|SelectOptionsList|SelectField|SelectMultiple|SelectOptionsList|SelectSingle|Spinner|Tab|Text|TextArea|TextInput|TinyMCE|ToggleDetails|ToggleFacade|Transition|TruncateText|View),?]+$/,
    // output of Pagination component substitutes the component name for the placeholder %s
    /Please update the following components: %s,Pagination/,

    // https://github.com/reactwg/react-18/discussions/82
    /Can't perform a React state update on an unmounted component/,
    /Warning: \[.*\] Did you forget to connect editorRef to your editor component\?/,
    // the block editor includes a ContentEditable and a delete button w/in an INSTUI Tab.
    '[Focusable] Exactly one focusable child is required',

    /or more breakpoints which are currently applied at the same time/,
  ],
}

export default function filterUselessConsoleMessages(originalConsole = console) {
  Object.keys(consoleMessagesToIgnore).forEach(key => {
    const original = originalConsole[key]
    originalConsole[key] = function () {
      const combinedMsg = Array.prototype.join.call(arguments)
      const shouldIgnore = pattern =>
        combinedMsg[typeof pattern === 'string' ? 'includes' : 'match'](pattern)
      if (consoleMessagesToIgnore[key].some(shouldIgnore)) return
      return original.apply(this, arguments)
    }
  })
}
