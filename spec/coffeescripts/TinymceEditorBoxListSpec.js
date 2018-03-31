/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import EditorBoxList from 'tinymce.editor_box_list'
import $ from 'jquery'

let list = null

QUnit.module('EditorBoxList', {
  setup() {
    $('#fixtures').append('<textarea id=a42></textarea>')
    list = new EditorBoxList()
  },
  teardown() {
    $('#a42').remove()
    $('#fixtures').empty()
    $('.ui-dialog').remove()
    $('.mce-tinymce').remove()
  }
})

test('constructor: property setting', () => {
  ok(list._textareas != null)
  ok(list._editors != null)
  ok(list._editor_boxes != null)
})

test('adding an editor box to the list', () => {
  const box = {}
  const node = $('#a42')
  list._addEditorBox('a42', box)
  equal(list._editor_boxes.a42, box)
  equal(list._textareas.a42.id, node.id)
})

test('removing an editorbox from storage', () => {
  list._addEditorBox('a42', {})
  list._removeEditorBox('a42')
  ok(list._editor_boxes.a42 == null)
  ok(list._textareas.a42 == null)
})

test('retrieving a text area', () => {
  const node = $('#a42')
  ok(list._getTextArea('a42').id === node.id)
})
