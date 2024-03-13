/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import 'jquery-migrate'
import 'jqueryui/menu'
import LongTextEditor from 'ui/features/gradebook/jquery/slickgrid.long_text_editor'

function editorArgs() {
  return {
    maxLength: 255,
    position: {
      top: 5,
      left: 5,
    },
    column: {
      field: 'default',
    },
    alt_container: document.getElementById('fixtures'),
    grid: {
      navigatePrev() {},
      navigateNext() {},
    },
    commitChanges() {},
    cancelChanges() {},
  }
}

QUnit.module('basic functionality', {
  setup() {
    this.editor = new LongTextEditor(editorArgs())
    this.editor.show()
  },

  teardown() {
    this.editor.destroy()
  },
})

test('renders a textarea', () => {
  const textareaElements = document.querySelectorAll('#fixtures textarea')

  strictEqual(textareaElements.length, 1)
})

test('renders a Save button', () => {
  const saveButton = document.querySelectorAll('#fixtures button')[0]

  strictEqual(saveButton.textContent, 'Save')
})

test('renders a Cancel button', () => {
  const cancelButton = document.querySelectorAll('#fixtures button')[1]

  strictEqual(cancelButton.textContent, 'Cancel')
})

test('focuses the textarea on initial render', () => {
  const textareaElement = document.querySelector('#fixtures textarea')

  strictEqual(document.activeElement, textareaElement)
})

QUnit.module('keyboard navigation', {
  stubbedArgs() {
    const args = editorArgs()
    args.grid.navigatePrev = sinon.stub()
    args.grid.navigateNext = sinon.stub()
    args.commitChanges = sinon.stub()
    args.cancelChanges = sinon.stub()

    return args
  },

  tabEvent() {
    return $.Event('keydown', {which: $.ui.keyCode.TAB, shiftKey: false})
  },

  shiftTabEvent() {
    return $.Event('keydown', {which: $.ui.keyCode.TAB, shiftKey: true})
  },

  setup() {
    this.args = this.stubbedArgs()
    this.editor = new LongTextEditor(this.args)
    this.editor.show()
  },

  teardown() {
    this.editor.destroy()
  },
})

test('when on the textarea, Shift-Tab navigates to the previous cell in the grid', function () {
  $('#fixtures textarea').trigger(this.shiftTabEvent())

  strictEqual(this.args.grid.navigatePrev.callCount, 1)
})

test('when on the textarea, Tab does not navigate to the next grid cell', function () {
  $('#fixtures textarea').trigger(this.tabEvent())

  strictEqual(this.args.grid.navigateNext.callCount, 0)
})

test('when on the textarea, Tab focusses the Save button', function () {
  const saveButton = $('#fixtures button')[0]
  $('#fixtures textarea').trigger(this.tabEvent())

  strictEqual(document.activeElement, saveButton)
})

test('when on the Save button, Shift-Tab focusses the textarea', function () {
  $('#fixtures button:first').trigger(this.shiftTabEvent())

  strictEqual(document.activeElement, $('#fixtures textarea')[0])
})

test('when on the Save button, Tab focusses the Cancel button', function () {
  const cancelButton = $('#fixtures button')[1]
  $('#fixtures button:first').trigger(this.tabEvent())

  strictEqual(document.activeElement, cancelButton)
})

test('when on the Cancel button, Shift-Tab focusses the Save button', function () {
  $('#fixtures button:last').trigger(this.shiftTabEvent())

  strictEqual(document.activeElement, $('#fixtures button')[0])
})

test('when on the Cancel button, Tab navigates to the next grid cell', function () {
  $('#fixtures button:last').trigger(this.tabEvent())

  strictEqual(this.args.grid.navigateNext.callCount, 1)
})
