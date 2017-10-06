#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery',
  'tinymce_plugins/instructure_links/linkable_editor',
  'jsx/shared/rce/RceCommandShim',
  'tinymce_plugins/instructure_links/links',
], ($, LinkableEditor, RceCommandShim, links) ->

  rawEditor = null

  QUnit.module "LinkableEditor",
    setup: ->
      $("#fixtures").html("<div id='some_editor' data-value='42'></div>")
      rawEditor = {
        id: 'some_editor',
        selection: {
          getContent: (()-> "Some Content")
        }
      }

    teardown: ->
      $("#fixtures").empty()

  test "can load the original element from the editor id", ->
    editor = new LinkableEditor(rawEditor)
    equal(editor.getEditor().data('value'), '42')

  test "shipping a new link to the editor instance", ->
    jqueryEditor = {
      editorBox: ->
      data: (arg) ->
        false if arg is 'remoteEditor'
        true if arg is 'rich_text'
    }
    editor = new LinkableEditor(rawEditor, jqueryEditor)
    text = "Link HREF"
    classes = ""
    expectedOpts = {
      classes: "",
      dataAttributes: undefined,
      selectedContent: "Some Content",
      url: "Link HREF"
    }
    edMock = @mock(jqueryEditor)
    edMock.expects("editorBox").withArgs('create_link', expectedOpts)
    editor.createLink(text, classes)

  test "createLink passes data attributes to create_link command", ->
    @stub(RceCommandShim, 'send')
    dataAttrs = {}
    le = new LinkableEditor({selection: {getContent: () => {}}})
    le.createLink('text', 'classes', dataAttrs)
    equal(RceCommandShim.send.firstCall.args[2].dataAttributes, dataAttrs)

  # this file wasn't running in jenkins because this file was named _spec.coffee instead of Spec.coffee
  # but these 2 specs were testing something that doesn't exist: LinkableEditor::extractTextContent
  # if that is something that actually should exist (but under a different name maybe),
  # we should rewrite these 2 test so there is coverage for it, othewise we should
  # remove these 2 skipped specs.
  QUnit.skip "pulling out text content from a text node", ->
    editor = new LinkableEditor(rawEditor)
    extractedText = editor.extractTextContent({
      getContent: ((opts)-> "Plain Text")
    })
    equal(extractedText, "Plain Text")

  QUnit.skip "extracting text from an IMG node with firefox api", ->
    editor = new LinkableEditor(rawEditor)
    extractedText = editor.extractTextContent({
      getContent: ((opts)->
        if opts? and opts.format is "text"
          "alt_text"
        else
          "<img alt='alt_text' src=''/>"
      )
    })
    equal(extractedText, "")

  QUnit.module "instructure_links link.js",
    setup: ->
      $('#fixtures').html('<div id="some_editor" data-value="42"><img class="iframe_placeholder" src="some_img.png" height="600" width="300"></div>')
    teardown: ->
      $("#fixtures").empty()

  test "links initEditor PreProcess event preserves iframe size", ->
    $editor = $(new LinkableEditor(rawEditor))
    event = $.Event('PreProcess')
    event.node = $('#fixtures')[0]
    links.initEditor($editor)
    $editor.trigger(event)
    $iframe = $('#fixtures').find('iframe')
    equal($iframe.attr('width'), 300)
    equal($iframe.attr('height'), 600)

