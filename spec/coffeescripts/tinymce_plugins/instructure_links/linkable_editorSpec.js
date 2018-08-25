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
import LinkableEditor from 'tinymce_plugins/instructure_links/linkable_editor'
import * as RceCommandShim from 'jsx/shared/rce/RceCommandShim'
import links from 'tinymce_plugins/instructure_links/links'

let rawEditor = null

QUnit.module('LinkableEditor', {
  setup() {
    $('#fixtures').html("<div id='some_editor' data-value='42'></div>")
    rawEditor = {
      id: 'some_editor',
      selection: {
        getContent: () => 'Some Content',
        getNode: () => {},
        getRng: () => {}
      }
    }
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('can load the original element from the editor id', () => {
  const editor = new LinkableEditor(rawEditor)
  equal(editor.getEditor().data('value'), '42')
})

test('shipping a new link to the editor instance', function() {
  const jqueryEditor = {
    editorBox() {},
    data(arg) {
      if (arg === 'remoteEditor') return false
      if (arg === 'rich_text') return true
    }
  }
  const editor = new LinkableEditor(rawEditor, jqueryEditor)
  const text = 'Link HREF'
  const classes = ''
  const expectedOpts = {
    classes: '',
    dataAttributes: undefined,
    selectedContent: 'Some Content',
    selectionDetails: {
      node: undefined,
      range: undefined
    },
    url: 'Link HREF'
  }
  const edMock = sandbox.mock(jqueryEditor)
  edMock.expects('editorBox').withArgs('create_link', expectedOpts)
  editor.createLink(text, classes)
})

test('createLink passes data attributes to create_link command', function() {
  sandbox.stub(RceCommandShim, 'send')
  const dataAttrs = {}
  const le = new LinkableEditor({selection: {
    getContent: () => ({}),
    getNode: () => {},
    getRng: () => {}
  }})
  le.createLink('text', 'classes', dataAttrs)
  equal(RceCommandShim.send.firstCall.args[2].dataAttributes, dataAttrs)
})

// this file wasn't running in jenkins because this file was named _spec.coffee instead of Spec.coffee
// but these 2 specs were testing something that doesn't exist: LinkableEditor::extractTextContent
// if that is something that actually should exist (but under a different name maybe),
// we should rewrite these 2 test so there is coverage for it, othewise we should
// remove these 2 skipped specs.
QUnit.skip('pulling out text content from a text node', () => {
  const editor = new LinkableEditor(rawEditor)
  const extractedText = editor.extractTextContent({
    getContent: opts => 'Plain Text'
  })
  equal(extractedText, 'Plain Text')
})

QUnit.skip('extracting text from an IMG node with firefox api', () => {
  const editor = new LinkableEditor(rawEditor)
  const extractedText = editor.extractTextContent({
    getContent(opts) {
      if (opts != null && opts.format === 'text') {
        return 'alt_text'
      } else {
        return "<img alt='alt_text' src=''/>"
      }
    }
  })
  equal(extractedText, '')
})

QUnit.module('instructure_links link.js', {
  setup() {
    $('#fixtures').html(
      '<div id="some_editor" data-value="42"><img class="iframe_placeholder" src="some_img.png" height="600" width="300"></div>'
    )
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('links initEditor PreProcess event preserves iframe size', () => {
  const $editor = $(new LinkableEditor(rawEditor))
  const event = $.Event('PreProcess')
  event.node = $('#fixtures')[0]
  links.initEditor($editor)
  $editor.trigger(event)
  const $iframe = $('#fixtures').find('iframe')
  equal($iframe.attr('width'), 300)
  equal($iframe.attr('height'), 600)
})

test("links initEditor PreProcess event doesn't use width/height attributes if style is present and contains those items", () => {
  $('#fixtures').html(
    '<div id="some_editor" data-value="42"><img class="iframe_placeholder" _iframe_style="height: 500px; width: 800px;" src="some_img.png" style="height: 500px; width: 800px;"></div>'
  )
  const $editor = $(new LinkableEditor(rawEditor))
  links.initEditor($editor)
  const event = $.Event('PreProcess')
  event.node = $('#fixtures')[0]
  $editor.trigger(event)
  const $iframe = $('#fixtures').find('iframe')
  equal($iframe.attr('style'), 'height: 500px; width: 800px;')
  ok(!$iframe.attr('width'))
  ok(!$iframe.attr('height'))
})

QUnit.module('updateLinks', {
  setup() {
    $('#fixtures').html(
      '<div id="some_editor" data-value="42"><p><span contenteditable="false" data-mce-object="iframe" class="mce-preview-object mce-object-iframe" data-mce-p-src="//simplydiffrient.com"><iframe style="width: 800px; height: 600px;" src="//simplydiffrient.com" frameborder="0"></iframe><span class="mce-shim"></span></span></p></div>'
    )
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('does not replace iframes with placebolders', () => {
  const $editor = $(new LinkableEditor(rawEditor))
  links.initEditor($editor)
  const mockEditor = {
    contentAreaContainer: $('<span>'),
    getBody: () => $('#fixtures')[0]
  }
  links.updateLinks(mockEditor)
  equal($('.iframe_placeholder').length, 0, 'should not replace iframes with placeholders')
})
