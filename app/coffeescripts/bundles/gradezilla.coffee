require [
  'jquery'
  'Backbone'
  'compiled/userSettings'
  'compiled/gradezilla/Gradebook'
  'compiled/views/gradezilla/NavigationPillView'
  'compiled/views/gradezilla/OutcomeGradebookView'
], ($, Backbone, userSettings, Gradebook, NavigationPillView, OutcomeGradebookView) ->

  class GradebookRouter extends Backbone.Router
    routes:
      '': 'tab'
      'tab-:viewName': 'tab'

    initialize: ->
      @isLoaded = false
      @views = {}
      @views.assignment = new Gradebook(ENV.GRADEBOOK_OPTIONS)

      if ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
        @views.outcome = @initOutcomes()

    initOutcomes: ->
      book = new OutcomeGradebookView(
        el: $('.outcome-gradebook-container'),
        gradebook: @views.assignment)
      book.render()
      @navigation = new NavigationPillView(el: $('.gradebook-navigation'))
      @navigation.on 'pillchange', @handlePillChange
      book

    handlePillChange: (viewname) =>
      @navigate('tab-'+viewname, trigger: true) if viewname

    tab: (viewName) ->
      viewName ||= userSettings.contextGet 'gradebook_tab'
      window.tab = viewName
      viewName = 'assignment' if viewName != 'outcome' || !@views.outcome
      @navigation.setActiveView(viewName) if @navigation
      $('.assignment-gradebook-container, .outcome-gradebook-container').addClass('hidden')
      $(".#{viewName}-gradebook-container").removeClass('hidden')
      @views[viewName].onShow()
      userSettings.contextSet 'gradebook_tab', viewName

  @router = new GradebookRouter
  Backbone.history.start()
