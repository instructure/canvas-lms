define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/grade_summary/ProgressBarView'
  'compiled/views/grade_summary/OutcomePopoverView'
  'compiled/views/grade_summary/OutcomeLineGraphView'
  'jst/grade_summary/outcome'
  'jst/outcomes/outcomePopover'
], (I18n, $, _, Backbone, ProgressBarView, OutcomePopoverView, OutcomeLineGraphView, template, popover_template) ->
  class OutcomeView extends Backbone.View
    tagName: 'li'
    className: 'outcome'
    template: template

    afterRender: ->
      @outcomeLineGraphView = new OutcomeLineGraphView({
        model: @model
      })

      @popover = new OutcomePopoverView({
        el: @$('.alignment-info i')
        model: @model
        template: popover_template
      })
      @popover.on 'outcomes:popover:open', =>
        @outcomeLineGraphView.setElement($("div.outcome-details > div.line-graph"))
        @outcomeLineGraphView.render()

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
        when 'undefined' then I18n.t('Unstarted')
        when 'remedial' then I18n.t('Well Below Mastery')
        when 'near' then I18n.t('Near Mastery')
        when 'mastery' then I18n.t('Meets Mastery')
        when 'exceeds' then I18n.t('Exceeds Mastery')
