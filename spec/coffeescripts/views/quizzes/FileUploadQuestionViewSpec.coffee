#
# Copyright (C) 2017 - present Instructure, Inc.
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
  'Backbone'
  'compiled/views/quizzes/FileUploadQuestionView'
  'compiled/models/File'
  'jquery'
], (Backbone, FileUploadQuestion, File, $) ->

  QUnit.module 'FileUploadQuestionView',
    setup: ->
      @oldEnv = window.ENV
      @model = new File({display_name: "foobar.jpg", id: 1}, {preflightUrl: 'url.com'})
      @view = new FileUploadQuestion(model: @model)
      @view.$el.appendTo('#fixtures')
      @view.render()

    teardown: ->
      window.ENV = @oldEnv
      @view.remove()
      @server?.restore()

  test '#processAttachment fires "attachmentManipulationComplete" event', ->
    spy = sinon.spy(@view, 'trigger')
    notOk spy.called, 'precondition'
    @view.processAttachment()
    ok spy.calledWith('attachmentManipulationComplete')
    @view.trigger.restore()

  test '#deleteAttachment fires "attachmentManipulationComplete" event', ->
    spy = sinon.spy(@view, 'trigger')
    notOk spy.called, 'precondition'
    @view.deleteAttachment($.Event( "keydown", { keyCode: 64 } ))
    ok spy.calledWith('attachmentManipulationComplete')
    @view.trigger.restore()
