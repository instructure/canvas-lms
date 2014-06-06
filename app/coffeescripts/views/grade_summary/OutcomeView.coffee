define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'jst/grade_summary/outcome'
], (I18n, _, Backbone, template) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template

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
