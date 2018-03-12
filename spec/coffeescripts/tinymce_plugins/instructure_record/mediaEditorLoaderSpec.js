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

import mediaEditorLoader from 'tinymce_plugins/instructure_record/mediaEditorLoader'
import * as RceCommandShim from 'jsx/shared/rce/RceCommandShim'

QUnit.module('mediaEditorLoader', {
  setup() {
    sinon.stub(RceCommandShim, 'send')
    this.mel = mediaEditorLoader

    this.collapseSpy = sinon.spy()
    this.selectSpy = sinon.spy()
    this.fakeED = {
      getBody() {},
      selection: {
        select: this.selectSpy,
        collapse: this.collapseSpy
      }
    }
  },

  teardown() {
    RceCommandShim.send.restore()
    window.$.mediaComment.restore && window.$.mediaComment.restore()
  }
})

test('properly makes link html', function() {
  const linkHTML = this.mel.makeLinkHtml('FOO', 'BAR', 'FOO title')
  const expectedResult =
    '<a href="/media_objects/FOO" class="instructure_inline_media_comment BAR' +
    '_comment" id="media_comment_FOO" data-alt="FOO title">this is a media comment</a>'

  equal(linkHTML, expectedResult)
})

test('creates a callback that will run callONRCE', function() {
  this.mel.commentCreatedCallback(this.fakeED, 'ID', 'TYPE')
  ok(RceCommandShim.send.called)
})

test('creates a callback that try to collapse a selection', function() {
  this.mel.commentCreatedCallback(this.fakeED, 'ID', 'TYPE')
  ok(this.selectSpy.called)
  ok(this.collapseSpy.called)
})

test('calls mediaComment with a function', function() {
  window.$.mediaComment
  sinon.spy(window.$, 'mediaComment')
  this.mel.insertEditor('foo')
  ok(window.$.mediaComment.calledWith('create', 'any'))
  const spyCall = window.$.mediaComment.getCall(0)
  const lastArgType = typeof spyCall.args[2]
  equal('function', lastArgType)
})
