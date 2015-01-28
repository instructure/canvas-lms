define [
  'i18n!outcomes'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'compiled/views/grade_summary/OutcomePopoverView'
  'jst/grade_summary/outcome'
  'jst/outcomes/outcomePopover'
], (I18n, _, Backbone, ProgressBarView, OutcomePopoverView, template, popover_template) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template

    afterRender: ->
      @popover = new OutcomePopoverView({
        el: @$('.alignment-info i')
        model: @model
        template: popover_template
      })

    initialize: ->
      super
      @progress = new ProgressBarView(model: @model)

    toJSON: ->
      json = super
      _.extend json,
        statusTooltip: @statusTooltip()
        progress: @progress

    statusTooltip: ->
      switch @model.status()
        when 'undefined' then I18n.t 'undefined', 'Unstarted'
        when 'remedial' then I18n.t 'remedial', 'Remedial'
        when 'near' then I18n.t 'near', 'Near mastery'
        when 'mastery' then I18n.t 'mastery', 'Mastery'
