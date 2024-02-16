/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import FileUploadQuestion from 'ui/features/take_quiz/backbone/views/FileUploadQuestionView'
import File from '@canvas/files/backbone/models/File'
import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('FileUploadQuestionView', {
  setup() {
    this.oldEnv = window.ENV
    this.model = new File(
      {
        display_name: 'foobar.jpg',
        id: 1,
      },
      {preflightUrl: 'url.com'}
    )
    this.view = new FileUploadQuestion({model: this.model})
    $('<input value="C:\\fakepath\\file.upload.zip" class="file-upload hidden" />').appendTo(
      this.view.$el
    )
    $('<input type="hidden" id="fileupload_in_progress" value="false"/>').appendTo(this.view.$el)
    this.view.$el.appendTo('#fixtures')
    this.view.render()
  },
  teardown() {
    window.ENV = this.oldEnv
    this.view.remove()
    this.server && this.server.restore()
  },
})

test('#checkForFileChange set file upload status to in_progress', function () {
  $('#fileupload_in_progress').val(false)
  const spy = sinon.stub(this.model, 'save')
  ok($('#fileupload_in_progress').val(), 'false')
  this.view.$fileUpload.val('C:\\fakepath\\file.upload.zip')
  this.view.checkForFileChange($.Event('keydown', {keyCode: 64}))
  ok($('#fileupload_in_progress').val(), 'true')
  spy.reset()
  spy.restore()
})

test('#processAttachment fires "attachmentManipulationComplete" event', function () {
  $('#fileupload_in_progress').val(true)
  const spy = sinon.spy(this.view, 'trigger')
  notOk(spy.called, 'precondition')
  ok($('#fileupload_in_progress').val(), 'true')
  this.view.processAttachment()
  ok(spy.calledWith('attachmentManipulationComplete'))
  ok($('#fileupload_in_progress').val(), 'false')
  this.view.trigger.restore()
})

test('#deleteAttachment fires "attachmentManipulationComplete" event', function () {
  const spy = sinon.spy(this.view, 'trigger')
  notOk(spy.called, 'precondition')
  this.view.deleteAttachment($.Event('keydown', {keyCode: 64}))
  ok(spy.calledWith('attachmentManipulationComplete'))
  this.view.trigger.restore()
})

test('#deleteAttachment clears file input', function () {
  equal(this.view.$fileUpload.val(), 'C:\\fakepath\\file.upload.zip')
  this.view.deleteAttachment($.Event('keydown', {keyCode: 64}))
  equal(this.view.$fileUpload.val(), '')
})
