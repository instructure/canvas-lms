require [
  'compiled/gradebook2/Gradebook'
  'compiled/views/gradebook/NavigationPillView'
  'compiled/views/gradebook/OutcomeGradebookView'
], (Gradebook, NavigationPillView, OutcomeGradebookView) ->

  isLoaded      = false
  initGradebook = () -> new Gradebook(ENV.GRADEBOOK_OPTIONS)
  initOutcomes  = (gradebook) ->
    navigation = new NavigationPillView(el: $('.gradebook-navigation'))
    book       = new OutcomeGradebookView(
      el: $('.outcome-gradebook-container'),
      gradebook: gradebook)
    book.render()

    navigation.on 'pillchange', (viewName) ->
      $('.gradebook-container, .outcome-gradebook-container').addClass('hidden')
      $(".#{viewName}-container").removeClass('hidden')
      loadOutcomes(book) if !isLoaded and viewName is 'outcome-gradebook'

  loadOutcomes = (book) ->
    isLoaded = true
    book.loadOutcomes()

  $(document).ready ->
    gradebook = initGradebook()
    initOutcomes(gradebook) if ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled
