/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jqueryui/menu'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('LongTextEditor')
/*
 * this is just LongTextEditor from slick.editors.js but with i18n and a
 * stupid dontblur class to cooperate with our gradebook's onGridBlur handler
 */
// @ts-expect-error
function LongTextEditor(args) {
  // @ts-expect-error
  let $input
  // @ts-expect-error
  let $wrapper
  // @ts-expect-error
  let $saveButton
  // @ts-expect-error
  let $cancelButton
  // @ts-expect-error
  let defaultValue
  // @ts-expect-error
  const scope = this

  // @ts-expect-error
  this.init = function () {
    const $container = args.alt_container ? $(args.alt_container) : $('body')

    $wrapper = $('<div/>')
      .addClass('dontblur')
      .css({
        'z-index': 10000,
        position: 'absolute',
        background: 'white',
        padding: '5px',
        border: '3px solid gray',
        '-moz-border-radius': '10px',
        'border-radius': '10px',
      })
      .appendTo($container)
    $input = $('<textarea>', {
      hidefocus: true,
      rows: 5,
      maxlength: args.maxLength,
    }).css({
      'background-color': 'white',
      width: '250px',
      height: '80px',
      border: 0,
      outline: 0,
    })

    $wrapper.empty().append($input)

    const buttonContainer = $('<div/>')
      .css({
        'text-align': 'right',
      })
      .appendTo($wrapper)
    const saveText = I18n.t('save', 'Save')
    const cancelText = I18n.t('cancel', 'Cancel')
    $saveButton = $('<button>').text(saveText).appendTo(buttonContainer)
    $cancelButton = $('<button>').text(cancelText).appendTo(buttonContainer)

    $saveButton.click(this.save)
    $cancelButton.click(this.cancel)
    $wrapper.keydown(this.handleKeyDown)

    scope.position(args.position)
    $input.focus().select()
  }

  // @ts-expect-error
  this.handleKeyDown = function (event) {
    const keyCode = event.which
    const target = event.target

    // @ts-expect-error
    if (target === $input.get(0)) {
      if (keyCode === $.ui.keyCode.ENTER && event.ctrlKey) {
        event.preventDefault()
        scope.save()
      } else if (keyCode === $.ui.keyCode.ESCAPE) {
        event.preventDefault()
        scope.cancel()
      } else if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault()
        args.grid.navigatePrev()
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault()
        // @ts-expect-error
        $saveButton.focus()
      }
      // @ts-expect-error
    } else if (target === $saveButton.get(0)) {
      if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault()
        // @ts-expect-error
        $input.focus()
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault()
        // @ts-expect-error
        $cancelButton.focus()
      }
      // @ts-expect-error
    } else if (target === $cancelButton.get(0)) {
      if (keyCode === $.ui.keyCode.TAB && event.shiftKey) {
        event.preventDefault()
        // @ts-expect-error
        $saveButton.focus()
      } else if (keyCode === $.ui.keyCode.TAB && !event.shiftKey) {
        // This explicit focus shifting allows JS specs to pass
        event.preventDefault()
        args.grid.navigateNext()
      }
    }
  }

  // @ts-expect-error
  this.save = function () {
    args.commitChanges()
  }

  // @ts-expect-error
  this.cancel = function () {
    // @ts-expect-error
    $input.val(defaultValue)
    args.cancelChanges()
  }

  // @ts-expect-error
  this.hide = function () {
    // @ts-expect-error
    $wrapper.hide()
  }

  // @ts-expect-error
  this.show = function () {
    // @ts-expect-error
    $wrapper.show()
  }

  // @ts-expect-error
  this.position = function () {
    // @ts-expect-error
    $wrapper.position({
      my: 'center top',
      at: 'center top',
      of: args.container,
    })
  }

  // @ts-expect-error
  this.destroy = function () {
    // @ts-expect-error
    $wrapper.remove()
  }

  // @ts-expect-error
  this.focus = function () {
    // @ts-expect-error
    $input.focus()
  }

  // @ts-expect-error
  this.loadValue = function (item) {
    // @ts-expect-error
    $input.val((defaultValue = item[args.column.field]))
    // @ts-expect-error
    $input.select()
  }

  // @ts-expect-error
  this.serializeValue = function () {
    // @ts-expect-error
    return $input.val()
  }

  // @ts-expect-error
  this.applyValue = function (item, state) {
    item[args.column.field] = state
  }

  // @ts-expect-error
  this.isValueChanged = function () {
    // @ts-expect-error
    return !($input.val() === '' && defaultValue == null) && $input.val() !== defaultValue
  }

  // @ts-expect-error
  this.validate = function () {
    return {
      valid: true,
      msg: null,
    }
  }

  // @ts-expect-error
  this.init()
}

export default LongTextEditor
