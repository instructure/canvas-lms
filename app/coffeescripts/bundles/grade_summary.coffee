require [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/userSettings'
  'compiled/collections/OutcomeSummaryCollection'
  'compiled/views/grade_summary/SectionView'
  'jqueryui/tabs'
  'jquery.disableWhileLoading'
  'grade_summary'
], ($, _, Backbone, CollectionView, userSettings, OutcomeSummaryCollection, SectionView) ->
  class GradebookSummaryRouter extends Backbone.Router
    routes:
      '': 'tab'
      'tab-:route': 'tab'

    initialize: ->
      return unless ENV.student_outcome_gradebook_enabled
      $('#content').tabs(activate: @activate)

      course_id = ENV.context_asset_string.replace('course_', '')
      user_id = ENV.student_id
      @outcomes = new OutcomeSummaryCollection([], course_id: course_id, user_id: user_id)
      @outcomeView = new CollectionView(el: $('#outcomes'), collection: @outcomes, itemView: SectionView)

    tab: (tab) ->
      if tab != 'outcomes' && tab != 'assignments'
        tab = userSettings.contextGet('grade_summary_tab') || 'assignments'
      $("a[href='##{tab}']").click()

    activate: (event, ui) =>
      tab = ui.newPanel.attr('id')
      router.navigate("#tab-#{tab}")
      @fetchOutcomes() if tab == 'outcomes'
      userSettings.contextSet('grade_summary_tab', tab)

    fetchOutcomes: ->
      @fetchOutcomes = $.noop
      @outcomes.fetch()

  @router = new GradebookSummaryRouter
  Backbone.history.start()
