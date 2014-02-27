require [
  'jquery'
  'Backbone'
  'compiled/gradebook2/Gradebook'
  'compiled/views/gradebook/NavigationPillView'
  'compiled/views/gradebook/OutcomeGradebookView'
], ($, Backbone, Gradebook, NavigationPillView, OutcomeGradebookView) ->
  class GradebookRouter extends Backbone.Router
    routes:
      '': 'showGrades'
      'outcomes': 'showOutcomes'

    initialize: ->
      @isLoaded      = false
      @views = {}
      @views.gradebook = new Gradebook(ENV.GRADEBOOK_OPTIONS)
      if ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
        @views['outcome-gradebook'] = @initOutcomes()

    initOutcomes: ->
      book = new OutcomeGradebookView(
        el: $('.outcome-gradebook-container'),
        gradebook: @views.gradebook)
      book.render()
      @navigation = new NavigationPillView(el: $('.gradebook-navigation'))
      @navigation.on 'pillchange', @handlePillChange
      book

    handlePillChange: (viewname) =>
      route = if viewname == 'gradebook' then '' else 'outcomes'
      @navigate(route, trigger: true)

    showGrades: ->
      @showView('gradebook')

    showOutcomes: ->
      @showView('outcome-gradebook')

    showView: (viewName) ->
      @navigation.setActiveView(viewName) if @navigation
      $('.gradebook-container, .outcome-gradebook-container').addClass('hidden')
      $(".#{viewName}-container").removeClass('hidden')
      @views[viewName].onShow()

  @router = new GradebookRouter
  Backbone.history.start()
