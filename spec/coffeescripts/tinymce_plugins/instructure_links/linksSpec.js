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
import EditorLinks from 'tinymce_plugins/instructure_links/links'
import LinkableEditor from 'tinymce_plugins/instructure_links/linkable_editor'

let selection = null
const alt = 'preview alt text'

QUnit.module('InstructureLinks Tinymce Plugin', {
  setup() {
    return (selection = {
      getContent() {
        return 'Selection Content'
      }
    })
  },
  teardown() {
    return $('.ui-dialog').remove()
  }
})

test('buttonToImg builds an img tag', () => {
  const target = {
    closest(str) {
      return {
        attr(str) {
          return 'some/img/url'
        }
      }
    }
  }
  equal(EditorLinks.buttonToImg(target), "<img src='some&#x2F;img&#x2F;url'/>")
})

test('buttonToImg is not vulnerable to XSS', () => {
  const target = {
    closest(str) {
      return {
        attr(str) {
          return "<script>alert('attacked');</script>"
        }
      }
    }
  }
  equal(
    EditorLinks.buttonToImg(target),
    "<img src='&lt;script&gt;alert(&#x27;attacked&#x27;);&lt;&#x2F;script&gt;'/>"
  )
})

test('prepEditorForDialog snapshots the current selection state', () => {
  let called = false
  const editor = {
    nodeChanged() {
      return (called = true)
    },
    selection
  }
  EditorLinks.prepEditorForDialog(editor)
  equal(called, true)
})

test('prepEditorForDialog wraps the editor in a linkable editor', () => {
  const editor = {
    nodeChanged() {},
    selection
  }
  const wrapper = EditorLinks.prepEditorForDialog(editor)
  equal(wrapper.selectedContent, 'Selection Content')
})

QUnit.module('InstructureLinks Tinymce Plugin: bindLinkSubmit', {
  setup() {
    this.box = $(`\
<div data-editor='editorId'> \
<form id='instructure_link_prompt_form'> \
<input class='prompt' value='promptValue'/> \
</form> \
<div class='inst-link-preview-alt'> \
<input value='${alt}'/> \
</div> \
</div>\
`)
    $('#fixtures').append(this.box)
    this.box.dialog()
    this.form = this.box.find('#instructure_link_prompt_form')
    this.editor = {
      createLink() {}
    }
    this.fetchClasses = () => 'classes'
  },
  teardown() {
    this.box.dialog('destroy')
    $('#fixtures').empty()
  }
})

test("it fires my 'done' callback when form gets submitted", function() {
  let called = false
  const done = () => (called = true)
  EditorLinks.bindLinkSubmit(this.box, this.editor, this.fetchClasses, done)
  this.form.trigger('submit')
  ok(called)
})

test('it removes any existing callbacks', function() {
  let called = false
  this.form.on('submit', () => (called = true))
  EditorLinks.bindLinkSubmit(this.box, this.editor, this.fetchClasses, () => {})
  this.form.trigger('submit')
  ok(!called)
})

test('it prevents the event from propogating up the chain', function() {
  let called = false
  this.box.on('submit', () => (called = true))
  EditorLinks.bindLinkSubmit(this.box, this.editor, this.fetchClasses, () => {})
  this.form.trigger('submit')
  ok(!called)
})

test('it closes the dialog box', function() {
  this.mock(this.box)
    .expects('dialog')
    .once()
    .withArgs('close')
  EditorLinks.bindLinkSubmit(this.box, this.editor, this.fetchClasses, () => {})
  return this.form.trigger('submit')
})

test('it inserts the link properly', function() {
  this.mock(this.editor)
    .expects('createLink')
    .once()
    .withArgs('promptValue', 'classes', {'preview-alt': 'preview alt text'})
  let called = false
  this.box.on('submit', () => (called = true))
  EditorLinks.bindLinkSubmit(this.box, this.editor, this.fetchClasses, () => {})
  return this.form.trigger('submit')
})

QUnit.module('InstructureLinks Tinymce Plugin: buildLinkClasses')

test('it removes any existing link-specific classes', () => {
  const box = $('<div></div>')
  const priorClasses = 'auto_open stylez inline_disabled stylee'
  const classes = EditorLinks.buildLinkClasses(priorClasses, box)
  equal(classes, ' stylez  stylee')
})

test('is adds in auto_open if checked', () => {
  const box = $(`<div> \
<input type='checkbox' checked class='auto_show_inline_content'/> \
</div>`)
  const priorClasses = ''
  const classes = EditorLinks.buildLinkClasses(priorClasses, box)
  equal(classes, ' auto_open')
})

test('it adds in inline_disabled if checked', () => {
  const box = $(`<div> \
<input type='checkbox' checked class='disable_inline_content'/> \
</div>`)
  const priorClasses = ''
  const classes = EditorLinks.buildLinkClasses(priorClasses, box)
  equal(classes, ' inline_disabled')
})

let renderDialog_ed = null

QUnit.module("InstructureLinks Tinymce Plugin: renderDialog", {
  setup() {
    renderDialog_ed = {
      getBody: () => null,
      nodeChanged: () => null,
      selection: {
        getContent: () => null,
        getNode: () => ({nodeName: 'SPAN'})
      }
    };
  },
  teardown() {
    $("#instructure_link_prompt").remove()
  }
})

test("it resets the text field if no existing link is selected", () => {
  EditorLinks.renderDialog(renderDialog_ed)
  const $prompt = $("#instructure_link_prompt .prompt")
  const $btn = $("#instructure_link_prompt .btn")
  $prompt.val("someurl")
  $btn.click()
  EditorLinks.renderDialog(renderDialog_ed)
  equal($prompt.val(), "")
})

test("it sets the text field to the href if link is selected", () => {
  EditorLinks.renderDialog(renderDialog_ed)
  const $prompt = $("#instructure_link_prompt .prompt")
  const $btn = $("#instructure_link_prompt .btn")
  $prompt.val("otherurl")
  $btn.click()
  const a = document.createElement('a')
  a.href = 'linkurl'
  renderDialog_ed.selection.getNode = () => a
  EditorLinks.renderDialog(renderDialog_ed)
  equal($prompt.val(), "linkurl")
})
