define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'jst/grade_summary/outcome'
], (I18n, _, Backbone, ProgressBarView, template) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    statusTooltip: ->
      switch @model.status()
        when 'undefined' then I18n.t 'undefined', 'Unstarted'
        when 'remedial' then I18n.t 'remedial', 'Remedial'
        when 'near' then I18n.t 'near', 'Near mastery'
        when 'mastery' then I18n.t 'mastery', 'Mastery'

    toJSON: ->
      json = super
      _.extend json,
        statusTooltip: @statusTooltip()
        progress: @progress
