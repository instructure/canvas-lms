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
  'tinymce_plugins/instructure_record/mediaEditorLoader',
  'jsx/shared/rce/RceCommandShim',
  'jquery'
], (mediaEditorLoader, RceCommandShim, $)->

  QUnit.module "mediaEditorLoader",
    setup: ->
      sinon.stub(RceCommandShim, 'send')
      @mel = mediaEditorLoader

      @collapseSpy = sinon.spy()
      @selectSpy = sinon.spy()
      @fakeED =
        getBody: ()->
        selection:
          select: @selectSpy
          collapse: @collapseSpy

    teardown: ->
      RceCommandShim.send.restore()
      window.$.mediaComment.restore  && window.$.mediaComment.restore()

  test 'properly makes link html', ->
    linkHTML = @mel.makeLinkHtml("FOO", "BAR", "FOO title")
    expectedResult =  '<a href="/media_objects/FOO" class="instructure_inline_media_comment BAR' +
      '_comment" id="media_comment_FOO" data-alt="FOO title">this is a media comment</a>';

    equal linkHTML, expectedResult

  test 'creates a callback that will run callONRCE', ->
    @mel.commentCreatedCallback(@fakeED, "ID", "TYPE")
    ok RceCommandShim.send.called

  test 'creates a callback that try to collapse a selection', ->
    @mel.commentCreatedCallback(@fakeED, "ID", "TYPE")
    ok @selectSpy.called
    ok @collapseSpy.called

  test 'calls mediaComment with a function', ->
    window.$.mediaComment
    sinon.spy(window.$, "mediaComment")
    @mel.insertEditor("foo")
    ok window.$.mediaComment.calledWith('create', 'any')
    spyCall = window.$.mediaComment.getCall(0)
    lastArgType = typeof spyCall.args[2]
    equal "function", lastArgType
