define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'compiled/views/grade_summary/OutcomePopoverView'
  'compiled/views/grade_summary/OutcomeDialogView'
  'jst/grade_summary/outcome'
], ($, _, Backbone, ProgressBarView, OutcomePopoverView, OutcomeDialogView, template) ->

  class OutcomeView extends Backbone.View
    className: 'outcome'
    events:
      'click .more-details' : 'show'
      'keydown .more-details' : 'show'
    tagName: 'li'
    template: template

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    afterRender: ->
      @popover = new OutcomePopoverView({
        el: @$('.more-details')
        model: @model
      })
      @dialog = new OutcomeDialogView({
        model: @model
      })

    show: (e) ->
      @dialog.show e

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress

