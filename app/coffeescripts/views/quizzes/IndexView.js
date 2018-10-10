#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'i18n!quizzes'
  'jquery'
  'underscore'
  'Backbone'
  './QuizItemGroupView'
  'jst/quizzes/IndexView'
  '../../jquery.rails_flash_notifications'
], (I18n, $, _, Backbone, QuizItemGroupView, template) ->

  class IndexView extends Backbone.View
    template: template

    el: '#content'

    @child 'assignmentView',  '[data-view=assignment]'
    @child 'openView',        '[data-view=open]'
    @child 'noQuizzesView',   '[data-view=no_quizzes]'
    @child 'surveyView',      '[data-view=surveys]'

    events:
      'keyup #searchTerm': 'keyUpSearch'
      'mouseup #searchTerm': 'keyUpSearch' #ie10 x-close workaround

    initialize: ->
      super
      @options.hasNoQuizzes          = @assignmentView.collection.length +
                                       @openView.collection.length == 0
      @options.hasAssignmentQuizzes  = @assignmentView.collection.length > 0
      @options.hasOpenQuizzes        = @openView.collection.length > 0
      @options.hasSurveys            = @surveyView.collection.length > 0

    views: ->
      [
        @options.assignmentView
        @options.openView
        @options.surveyView
      ]

    keyUpSearch: _.debounce ->
      @filterResults()
      @announceCount()
    , 200

    filterResults: =>
      _.each @views(), (view) =>
        view.filterResults($('#searchTerm').val())

    announceCount: =>
      searchTerm = $('#searchTerm').val()
      return if searchTerm == '' || searchTerm == null

      matchingQuizCount = _.reduce(@views(), (runningCount, view) =>
        return runningCount + view.matchingCount(searchTerm)
      , 0)
      @announceMatchingQuizzes(matchingQuizCount)

    announceMatchingQuizzes: (numQuizzes) ->
      msg = I18n.t({
          one: "1 quiz found."
          other: "%{count} quizzes found."
          zero: "No matching quizzes found."
        }, count: numQuizzes
      )
      $.screenReaderFlashMessageExclusive(msg)
