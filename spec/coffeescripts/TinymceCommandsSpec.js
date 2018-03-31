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

import $ from 'jquery'
import tinymce from 'compiled/editor/stocktiny'
import {remove, insertLink} from 'tinymce.commands'
import EditorBoxList from 'tinymce.editor_box_list'

let testbed = null
let list = null
let textarea = null

QUnit.module('Tinymce Commands -> removing an editor', {
  setup() {
    testbed = $("<div id='command-testbed'></div>")
    $('#fixtures').append(testbed)
    textarea = $("<textarea id='a43' data-rich_text='true'></textarea>")
    testbed.append(textarea)
    list = new EditorBoxList()
  },
  teardown() {
    list = null
    testbed = null
    textarea.remove()
    $('#command-testbed').remove()
    $('#fixtures').empty()
  }
})

test('it un-rich-texts the DOM element', () => {
  remove(textarea, list)
  equal(textarea.data('rich_text'), false)
})

test('it causes tinymce to forget about the editor', () => {
  tinymce.init({selector: '#command-testbed textarea#a43'})
  equal(tinymce.activeEditor.id, 'a43')
  remove(textarea, list)
  equal(undefined, tinymce.activeEditor)
})

test('it unregisters the editor from our global list', () => {
  const box = {}
  list._addEditorBox('a43', box)
  equal(box, list._editor_boxes.a43)
  remove(textarea, list)
  equal(undefined, list._editor_boxes.a43)
})

QUnit.module('Tinymce Commands -> inserting content with tables', {
  setup() {
    testbed = $("<div id='command-testbed'></div>")
    $('#fixtures').append(testbed)
  },
  teardown() {
    textarea.remove()
    $('#command-testbed').remove()
    $('#fixtures').empty()
    testbed = null
    list = null
  }
})

test('it keeps surrounding html when inserting links in a table', () => {
  textarea = $(`
    <textarea id='a43' data-rich_text='true'>
      <table>
        <tr>
          <td><span id='span'><a id='link' href='#'>Test Link</a></span></td>
        </tr>
      </table>
    </textarea>
  `)
  testbed.append(textarea)
  list = new EditorBoxList()
  tinymce.init({selector: '#command-testbed textarea#a43'})
  const editor = tinymce.get('a43')
  editor.selection.select(editor.dom.select('a')[0])
  const new_link_id = 'new_link'
  const linkAttr = {
    target: '',
    title: 'New Link',
    href: '/courses/1/pages/blah',
    class: '',
    id: new_link_id
  }
  insertLink('a43', null, linkAttr)
  equal(
    editor.selection.select(editor.dom.select('span')[0]).childNodes[0].id,
    new_link_id,
    'keeps surrounding span tag'
  )
})
