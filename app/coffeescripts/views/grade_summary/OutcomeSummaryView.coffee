define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/SectionView'
  'compiled/views/grade_summary/OutcomeDetailView'
], ($, _, Backbone, CollectionView, SectionView, OutcomeDetailView) ->
  class OutcomeSummaryView extends CollectionView
    @optionProperty 'course_id'
    @optionProperty 'user_id'
    @optionProperty 'toggles'

    itemView: SectionView

    initialize: ->
      super
      @outcomeDetailView = new OutcomeDetailView(user_id: @user_id, course_id: @course_id)
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
      @toggles.find('.icon-expand').click =>
        @$('li.group').addClass('expanded')
      @toggles.find('.icon-collapse').click =>
        @$('li.group').removeClass('expanded')
