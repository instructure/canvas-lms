/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

/**
 * jQuery wrapper for Vitest tests
 *
 * This module exports jQuery with all necessary plugins pre-attached.
 * By aliasing 'jquery' to this module in vitest.config.ts, we ensure
 * all imports of jQuery get the same instance with plugins attached.
 */

// We need to get jQuery without triggering our own alias
// Use createRequire to bypass ESM resolution
import {createRequire} from 'module'
const require = createRequire(import.meta.url)

const jqueryActual = require('jquery') as JQueryStatic
const $: JQueryStatic = jqueryActual

// Add toJSON plugin for Backbone views
// This is a simplified implementation that doesn't depend on serializeForm
// to avoid circular dependencies. It handles the common case of form serialization.
$.fn.toJSON = function () {
  const json: Record<string, unknown> = {}
  $(this)
    .find('input, select, textarea')
    .each(function () {
      const $el = $(this)
      const name = $el.attr('name')
      if (name) {
        // Handle checkboxes specially
        if ($el.attr('type') === 'checkbox') {
          json[name] = $el.is(':checked')
        } else if ($el.attr('type') === 'radio') {
          if ($el.is(':checked')) {
            json[name] = $el.val()
          }
        } else {
          json[name] = $el.val()
        }
      }
    })
  return json
}

// Add jQuery UI plugin stubs - these don't work properly in jsdom
// but need to exist to prevent "X is not a function" errors.
// Type errors are suppressed because these stubs don't match the complex
// jQuery UI type signatures that return different types based on arguments.
const chainableStub = function (this: JQuery) {
  return this
}
$.fn.tooltip = chainableStub
$.fn.tabs = chainableStub
$.fn.autocomplete = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.dialog = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.sortable = chainableStub
$.fn.draggable = chainableStub
$.fn.droppable = chainableStub
$.fn.resizable = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.datepicker = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.menu = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.slider = chainableStub
$.fn.selectable = chainableStub
$.fn.accordion = chainableStub
$.fn.progressbar = chainableStub
// @ts-expect-error - stub doesn't match complex jQuery UI signature
$.fn.spinner = chainableStub
$.fn.button = chainableStub
$.fn.buttonset = chainableStub

// Canvas custom jQuery plugins
$.fn.toggleAccessibly = function (this: JQuery, visible?: boolean) {
  if (visible) {
    this.show()
  } else {
    this.hide()
  }
  return this
}
$.fn.disableWhileLoading = chainableStub

export default $
export {$ as jQuery}
