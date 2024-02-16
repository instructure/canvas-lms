/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import EditorToggle from '@canvas/editor-toggle'
import RichContentEditor from '@canvas/rce/RichContentEditor'

const fixtures = $('#fixtures')
let containerDiv = null

QUnit.module('EditorToggle', {
  setup() {
    containerDiv = $('<div></div>')
    fixtures.append(containerDiv)
  },
  teardown() {
    containerDiv.remove()
    fixtures.empty()
  },
})

test('constructor initializes textarea container', () => {
  const et = new EditorToggle($('<div/>'))
  ok(et.textAreaContainer.has(et.textArea))
})

test('it passes tinyOptions into getRceOptions', () => {
  const tinyOpts = {width: '100'}
  const initialOpts = {tinyOptions: tinyOpts}
  const editorToggle = new EditorToggle(containerDiv, initialOpts)
  const opts = editorToggle.getRceOptions()
  equal(opts.tinyOptions, tinyOpts)
})

test('it defaults tinyOptions to an empty object if none are given', () => {
  const initialOpts = {someStuff: null}
  const editorToggle = new EditorToggle(containerDiv, initialOpts)
  const opts = editorToggle.getRceOptions()
  deepEqual(opts.tinyOptions, {})
})

test('@options.rceOptions argument is not modified after initialization', () => {
  const rceOptions = {
    focus: false,
    otherStuff: '',
  }
  const initialOpts = {
    someStuff: null,
    rceOptions,
  }
  const editorToggle = new EditorToggle(containerDiv, initialOpts)
  editorToggle.getRceOptions()
  equal(editorToggle.options.rceOptions.focus, false)
  equal(editorToggle.options.rceOptions.otherStuff, '')
})

test('@options.rceOptions can extend the default RichContentEditor opts', () => {
  const rceOptions = {
    focus: false,
    otherStuff: '',
  }
  const initialOpts = {
    someStuff: null,
    rceOptions,
  }
  const editorToggle = new EditorToggle(containerDiv, initialOpts)
  const opts = editorToggle.getRceOptions()
  ok(opts.tinyOptions)
  equal(opts.focus, false)
  equal(opts.otherStuff, rceOptions.otherStuff)
})

test("createDone does not throw error when editButton doesn't exist", () => {
  sandbox.stub($.fn, 'click').callsArg(0)
  EditorToggle.prototype.createDone.call({
    options: {doneText: ''},
    display() {},
  })
  ok($.fn.click.called)
})

test('createTextArea returns element with unique id', () => {
  const ta1 = EditorToggle.prototype.createTextArea()
  const ta2 = EditorToggle.prototype.createTextArea()
  ok(ta1.attr('id'))
  ok(ta2.attr('id'))
  notEqual(ta1.attr('id'), ta2.attr('id'))
})

test('replaceTextArea', () => {
  sandbox.stub(RichContentEditor, 'destroyRCE')
  sandbox.stub($.fn, 'insertBefore')
  sandbox.stub($.fn, 'remove')
  sandbox.stub($.fn, 'detach')

  const textArea = $('<textarea/>')
  const et = {
    el: $('<div/>'),
    textAreaContainer: $('<div/>'),
    textArea,
    createTextArea: () => ({}),
  }
  EditorToggle.prototype.replaceTextArea.call(et)

  ok($.fn.insertBefore.calledOn(et.el), 'inserts el')
  ok($.fn.insertBefore.calledWith(et.textAreaContainer), 'before container')
  ok($.fn.remove.calledOn(textArea), 'old textarea removed')
  ok(RichContentEditor.destroyRCE.calledWith(textArea), 'destroys rce')
  ok($.fn.detach.calledOn(et.textAreaContainer), 'removes container')
})

test('getContent removes MathML', () => {
  containerDiv.append(
    $('<div>Math image goes here</div><div class="hidden-readable">MathML goes here</div>')
  )
  const et = new EditorToggle(containerDiv)
  equal(et.getContent(), '<div>Math image goes here</div>')
})

test('getContent leaves plain text alone', () => {
  containerDiv.text('this is plain text')
  const et = new EditorToggle(containerDiv)
  equal(et.getContent(), 'this is plain text')
})
