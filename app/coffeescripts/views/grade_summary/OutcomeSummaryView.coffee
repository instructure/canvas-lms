define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/SectionView'
  'compiled/views/grade_summary/OutcomeDetailView'
], ($, _, Backbone, CollectionView, SectionView, OutcomeDetailView) ->
  class OutcomeSummaryView extends CollectionView
    @optionProperty 'toggles'

    itemView: SectionView

    initialize: ->
      super
      @outcomeDetailView = new OutcomeDetailView()
      @bindToggles()

    show: (path) ->
      @fetch()
      if path
        outcome_id = parseInt(path)
        outcome = @collection.outcomeCache.get(outcome_id)
        @outcomeDetailView.show(outcome) if outcome
      else
        @outcomeDetailView.close()

    fetch: ->
      @fetch = $.noop
      @collection.fetch()

    bindToggles: ->
      $collapseToggle = $('div.outcome-toggles a.icon-collapse')
      $expandToggle = $('div.outcome-toggles a.icon-expand')
      @toggles.find('.icon-expand').click =>
        @$('li.group').addClass('expanded')
        @$('div.group-description').attr('aria-expanded', "true")
        $expandToggle.attr('disabled', 'disabled')
        $expandToggle.attr('aria-disabled', 'true')
        $collapseToggle.removeAttr('disabled')
        $collapseToggle.attr('aria-disabled', 'false')
        $("div.groups").focus()
      @toggles.find('.icon-collapse').click =>
        @$('li.group').removeClass('expanded')
        @$('div.group-description').attr('aria-expanded', "false")
        $collapseToggle.attr('disabled', 'disabled')
        $collapseToggle.attr('aria-disabled', 'true')
        $expandToggle.removeAttr('disabled')
        $expandToggle.attr('aria-disabled', 'false')
