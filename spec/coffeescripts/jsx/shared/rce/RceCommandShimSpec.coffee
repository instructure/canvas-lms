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
  'jsx/shared/rce/RceCommandShim',
  'wikiSidebar',
  'helpers/fixtures'
], (RceCommandShim, wikiSidebar, fixtures) ->

  remoteEditor = null
  QUnit.module 'RceCommandShim - send',
    setup: ->
      fixtures.setup()
      @$target = fixtures.create('<textarea />')
      @$target.editorBox = ()->{}
      remoteEditor = {
        hidden: false,
        isHidden: (()=> return remoteEditor.hidden)
        call: sinon.stub().returns("methodResult")
      }

    teardown: ->
      fixtures.teardown()

  test "just forwards through target's remoteEditor if set", ->
    @$target.data('remoteEditor', remoteEditor)
    equal RceCommandShim.send(@$target, "methodName", "methodArgument"), "methodResult"
    ok remoteEditor.call.calledWith("methodName", "methodArgument")

  test "uses editorBox if remoteEditor is not set but rich_text is set", ->
    sinon.stub(@$target, 'editorBox').returns("methodResult")
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', true)
    equal RceCommandShim.send(@$target, "methodName", "methodArgument"), "methodResult"
    ok @$target.editorBox.calledWith("methodName", "methodArgument")

  test "returns false for exists? if neither remoteEditor nor rich_text are set (e.g. load failed)", ->
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', null)
    equal RceCommandShim.send(@$target, "exists?"), false

  test "returns target's val() for get_code if neither remoteEditor nor rich_text are set (e.g. load failed)", ->
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', null)
    @$target.val('current raw value')
    equal RceCommandShim.send(@$target, "get_code"), 'current raw value'

  test "returns target val for get_code if editor is hidden", ->
    remoteEditor.hidden = true
    @$target.data('remoteEditor', remoteEditor)
    @$target.val('current HTML value')
    equal RceCommandShim.send(@$target, "get_code"), 'current HTML value'

  test "uses the editors get_code if visible", ->
    remoteEditor.hidden = false
    @$target.data('remoteEditor', remoteEditor)
    equal RceCommandShim.send(@$target, "get_code"), 'methodResult'

  test "transforms create_link call for remote editor", ->
    url = 'http://someurl'
    classes = 'one two'
    previewAlt = 'alt text for preview'
    @$target.data('remoteEditor', remoteEditor)
    RceCommandShim.send(@$target, "create_link",
      url: url
      classes: classes
      dataAttributes: {'preview-alt': previewAlt}
    )
    ok remoteEditor.call.calledWithMatch('insertLink',
      href: url
      'class': classes
      'data-preview-alt': previewAlt
    )

  QUnit.module 'RceCommandShim - focus',
    setup: ->
      fixtures.setup()
      @$target = fixtures.create('<textarea />')
      editor = {focus: ()->{}}
      tinymce = {get: ()->editor}
      RceCommandShim.setTinymce(tinymce)

    teardown: ->
      fixtures.teardown()

  test "just forwards through target's remoteEditor if set", ->
    remoteEditor = { focus: sinon.spy() }
    @$target.data('remoteEditor', remoteEditor)
    RceCommandShim.focus(@$target)
    ok remoteEditor.focus.called

  test "uses wikiSidebar if remoteEditor is not set but rich_text is set", ->
    sinon.spy(wikiSidebar, 'attachToEditor')
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', true)
    RceCommandShim.focus(@$target)
    ok wikiSidebar.attachToEditor.calledWith(@$target)
    wikiSidebar.attachToEditor.restore()

  QUnit.module 'RceCommandShim - destroy',
    setup: ->
      fixtures.setup()
      @$target = fixtures.create('<textarea />')
      @$target.editorBox = ()->{}

    teardown: ->
      fixtures.teardown()

  test "forwards through target's remoteEditor if set", ->
    remoteEditor = { destroy: sinon.spy() }
    @$target.data('remoteEditor', remoteEditor)
    RceCommandShim.destroy(@$target)
    ok remoteEditor.destroy.called

  test "clears target's remoteEditor afterwards if set", ->
    remoteEditor = { destroy: sinon.spy() }
    @$target.data('remoteEditor', remoteEditor)
    RceCommandShim.destroy(@$target)
    equal @$target.data('remoteEditor'), undefined

  test "uses editorBox if remoteEditor is not set but rich_text is set", ->
    sinon.spy(@$target, 'editorBox')
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', true)
    RceCommandShim.destroy(@$target)
    ok @$target.editorBox.calledWith("destroy")

  test "does not except if remoteEditor and editorBox are not set", ->
    # sinon.spy(@$target, 'editorBox')
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', true)
    RceCommandShim.destroy(@$target)
    ok true, 'function did not throw an exception'
