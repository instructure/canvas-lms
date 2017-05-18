#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/userSettings'
  'compiled/collections/OutcomeSummaryCollection'
  'compiled/views/grade_summary/OutcomeSummaryView'
  'jsx/grading/GradeSummary'
  'jqueryui/tabs'
  'jquery.disableWhileLoading'
], ($, _, Backbone, userSettings, OutcomeSummaryCollection, OutcomeSummaryView, GradeSummary) ->
  # Ensure the gradebook summary code has had a chance to setup all its handlers
  GradeSummary.setup()

  class GradebookSummaryRouter extends Backbone.Router
    routes:
      '': 'tab'
      'tab-:route(/*path)': 'tab'

    initialize: ->
      return unless ENV.student_outcome_gradebook_enabled
      $('#content').tabs(activate: @activate)

      course_id = ENV.context_asset_string.replace('course_', '')
      user_id = ENV.student_id
      @outcomes = new OutcomeSummaryCollection([], course_id: course_id, user_id: user_id)
      @outcomeView = new OutcomeSummaryView
        el: $('#outcomes'),
        collection: @outcomes,
        toggles: $('.outcome-toggles')

    tab: (tab, path) ->
      if tab != 'outcomes' && tab != 'assignments'
        tab = userSettings.contextGet('grade_summary_tab') || 'assignments'
      $("a[href='##{tab}']").click()
      if tab == 'outcomes'
        @outcomeView.show(path)
        $('.outcome-toggles').show()
      else
        $('.outcome-toggles').hide()

    activate: (event, ui) ->
      tab = ui.newPanel.attr('id')
      router.navigate("#tab-#{tab}", {trigger: true})
      userSettings.contextSet('grade_summary_tab', tab)

  router = new GradebookSummaryRouter
  Backbone.history.start()
