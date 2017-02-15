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
