require [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/CollectionView'
  'compiled/userSettings'
  'compiled/views/gradebook/StudentOutcomeView'
  'jqueryui/tabs'
  'jquery.disableWhileLoading'
  'grade_summary'
], ($, _, Backbone, CollectionView, userSettings, StudentOutcomeView) ->
  class GradebookSummaryRouter extends Backbone.Router
    routes:
      '': 'tab'
      'tab-:route': 'tab'

    initialize: ->
      return unless ENV.student_outcome_gradebook_enabled
      $('#content').tabs(activate: @activate)

    tab: (tab) ->
      if tab != 'outcomes' && tab != 'assignments'
        tab = userSettings.contextGet('grade_summary_tab') || 'assignments'
      $("a[href='##{tab}']").click()

    activate: (event, ui) =>
      tab = ui.newPanel.attr('id')
      router.navigate("#tab-#{tab}")
      @loadOutcomes() if tab == 'outcomes'
      userSettings.contextSet('grade_summary_tab', tab)

    loadOutcomes: ->
      @loadOutcomes = $.noop
      course_id = ENV.context_asset_string.replace('course_', '')
      user_id = ENV.student_id
      url = "/api/v1/courses/#{course_id}/outcome_rollups?user_ids[]=#{user_id}&include[]=outcomes"
      whenLoaded = $.getJSON(url)
      $('#outcomes').disableWhileLoading(whenLoaded)
      whenLoaded.done(@handleOutcomes)

    handleOutcomes: (response) =>
      scores = _.object(_.map(response.rollups[0].scores, (score) ->
        [score.links.outcome, score.score]
      ))
      outcomes = new Backbone.Collection(_.map(response.linked.outcomes, (outcome) ->
        new Backbone.Model(_.extend({score: scores[outcome.id]}, outcome))
      ))
      new CollectionView(
        el: $('#outcomes')
        itemView: StudentOutcomeView
        collection: outcomes
      ).render()

  @router = new GradebookSummaryRouter
  Backbone.history.start()
