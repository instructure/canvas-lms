define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'jst/grade_summary/alignment'
], (I18n, _, Backbone, ProgressBarView, template) ->
  class AlignmentView extends Backbone.View
    tagName: 'li'
    className: 'alignment'
    template: template

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress
