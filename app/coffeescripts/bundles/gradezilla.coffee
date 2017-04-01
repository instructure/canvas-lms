#
# Copyright (C) 2016 - 2017 Instructure, Inc.
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
#

require [
  'jquery'
  'Backbone'
  'compiled/userSettings'
  'compiled/gradezilla/Gradebook'
  'compiled/views/gradezilla/OutcomeGradebookView'
], ($, Backbone, UserSettings, Gradebook, OutcomeGradebookView) ->

  getGradebookTab = () ->
    UserSettings.contextGet 'gradebook_tab'

  setGradebookTab = (view) ->
    UserSettings.contextSet 'gradebook_tab', view

  class GradebookRouter extends Backbone.Router
    routes:
      '': 'tab'
      'tab-assignment': 'tabAssignment'
      'tab-outcome': 'tabOutcome'
      '*path':  'tab'

    initialize: ->
      @isLoaded = false
      @views = {}
      ENV.GRADEBOOK_OPTIONS.assignmentOrOutcome = getGradebookTab()
      ENV.GRADEBOOK_OPTIONS.navigate = @navigate.bind(@)
      @views.assignment = new Gradebook(ENV.GRADEBOOK_OPTIONS)
      @views.outcome = @initOutcomes() if ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
      @

    initOutcomes: ->
      book = new OutcomeGradebookView(el: $('.outcome-gradebook'), gradebook: @views.assignment)
      book.render()
      book

    tabOutcome: ->
      window.tab = 'outcome'
      $('.assignment-gradebook-container').addClass('hidden')
      $('.outcome-gradebook-container > div').removeClass('hidden')
      @views.outcome.onShow()
      setGradebookTab('outcome')

    tabAssignment: ->
      window.tab = 'assignment'
      $('.outcome-gradebook-container > div').addClass('hidden')
      $('.assignment-gradebook-container').removeClass('hidden')
      @views.assignment.onShow()
      setGradebookTab('assignment')

    tab: ->
      view = getGradebookTab()
      window.tab = view
      if view != 'outcome' || !@views.outcome
        view = 'assignment'
      $('.assignment-gradebook-container, .outcome-gradebook-container > div').addClass('hidden')
      $(".#{view}-gradebook-container, .#{view}-gradebook-container div").removeClass('hidden')
      @views[view].onShow()
      setGradebookTab(view)

  new GradebookRouter
  Backbone.history.start()
