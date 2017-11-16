#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'jquery'
  'compiled/editor/EditorToggle'
  'jsx/shared/rce/RichContentEditor'
], ($, EditorToggle, RichContentEditor) ->

  fixtures = $("#fixtures")
  containerDiv = null

  QUnit.module "EditorToggle",
    setup: ->
      containerDiv = $("<div></div>")
      fixtures.append(containerDiv)
    teardown: ->
      containerDiv.remove()
      fixtures.empty()

  test "constructor initializes textarea container", ->
    et = new EditorToggle($('<div/>'))
    ok et.textAreaContainer.has(et.textArea)

  test "it passes tinyOptions into getRceOptions", ->
    tinyOpts = {width: '100'}
    initialOpts = {tinyOptions: tinyOpts}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    equal(opts.tinyOptions, tinyOpts)

  test "it defaults tinyOptions to an empty object if none are given", ->
    initialOpts = {someStuff: null}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    deepEqual(opts.tinyOptions, {})

  test "@options.rceOptions argument is not modified after initialization", ->
    rceOptions = {focus: false, otherStuff: ''}
    initialOpts = {someStuff: null, rceOptions}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    editorToggle.getRceOptions()

    equal editorToggle.options.rceOptions.focus, false
    equal editorToggle.options.rceOptions.otherStuff, ''

  test "@options.rceOptions can extend the default RichContentEditor opts", ->
    rceOptions = {focus: false, otherStuff: ''}
    initialOpts = {someStuff: null, rceOptions}
    editorToggle = new EditorToggle(containerDiv, initialOpts)
    opts = editorToggle.getRceOptions()

    ok opts.tinyOptions
    equal opts.focus, false
    equal opts.otherStuff, rceOptions.otherStuff

  test "createDone does not throw error when editButton doesn't exist", ->
    @stub($.fn, 'click').callsArg(0)
    EditorToggle::createDone.call
      options: {doneText: ''}
      display: ->
    ok $.fn.click.called

  test "createTextArea returns element with unique id", ->
    ta1 = EditorToggle::createTextArea()
    ta2 = EditorToggle::createTextArea()
    ok ta1.attr('id')
    ok ta2.attr('id')
    notEqual(ta1.attr('id'), ta2.attr('id'))

  test 'replaceTextArea', ->
    @stub(RichContentEditor, 'destroyRCE')
    @stub($.fn, 'insertBefore')
    @stub($.fn, 'remove')
    @stub($.fn, 'detach')

    textArea = $('<textarea/>')
    et =
      el: $('<div/>')
      textAreaContainer: $('<div/>')
      textArea: textArea
      createTextArea: () => {}

    EditorToggle::replaceTextArea.call(et)

    ok $.fn.insertBefore.calledOn(et.el), 'inserts el'
    ok $.fn.insertBefore.calledWith(et.textAreaContainer), 'before container'
    ok $.fn.remove.calledOn(textArea), 'old textarea removed'
    ok RichContentEditor.destroyRCE.calledWith(textArea), 'destroys rce'
    ok $.fn.detach.calledOn(et.textAreaContainer), 'removes container'

  test 'edit', ->
    fresh = {}
    content = 'content'
    textArea = $('<textarea/>')
    et =
      el: $('<div/>')
      textAreaContainer: $('<div/>')
      textArea: textArea
      done: $('<div/>')
      getContent: -> content
      getRceOptions: ->
      trigger: ->
      options: {}

    @stub(RichContentEditor, 'loadNewEditor')
    @stub(RichContentEditor, 'freshNode').returns(fresh)
    @stub($.fn, 'val')
    @stub($.fn, 'insertBefore')
    @stub($.fn, 'detach')

    EditorToggle::edit.call(et)

    ok $.fn.val.calledOn(textArea), 'set value of textarea'
    ok $.fn.val.calledWith(content), 'with correct content'

    ok $.fn.insertBefore.calledOn(et.textAreaContainer), 'inserts container'
    ok $.fn.insertBefore.calledWith(et.el), 'before el'
    ok $.fn.detach.calledOn(et.el), 'removes el'

    ok RichContentEditor.loadNewEditor.calledWith(textArea), 'loads rce'

    ok RichContentEditor.freshNode.calledWith(textArea), 'gets fresh node'
    equal et.textArea, fresh, 'sets @textArea to fresh node'
