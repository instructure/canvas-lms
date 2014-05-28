define [
  'jquery'
  'jst/assignments/ExternalContentHomeworkSubmissionView'
], ($, template) ->

  class ExternalContentHomeworkSubmissionView extends Backbone.View
    template: template
    @optionProperty 'externalTool'

    events:
      'click .relaunch-tool': '_relaunchTool'
      'click .submit_button': '_triggerSubmit'
      'click .cancel_button': '_triggerCancel'

    _relaunchTool: (event) =>
      event.preventDefault()
      event.stopPropagation()
      @trigger 'relaunchTool', @externalTool, @model

    _triggerCancel: (event) =>
      event.preventDefault()
      event.stopPropagation()
      @trigger 'cancel', @externalTool, @model

    _triggerSubmit: (event) =>
      event.preventDefault()
      event.stopPropagation()
      @model.set('comment', @$el.find('.submission_comment').val())
      @trigger 'submit', @externalTool, @model
