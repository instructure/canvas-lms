define [
  'underscore'
  'Backbone'
  'compiled/views/quizzes/QuizItemGroupView'
  'jst/quizzes/IndexView'
], (_, Backbone, QuizItemGroupView, template) ->

  class IndexView extends Backbone.View
    template: template

    el: '#content'

    @child 'assignmentView',  '[data-view=assignment]'
    @child 'openView',        '[data-view=open]'
    @child 'noQuizzesView',   '[data-view=no_quizzes]'
    @child 'surveyView',      '[data-view=surveys]'

    events:
      'keyup #searchTerm': 'keyUpSearch'

    initialize: ->
      super
      @options.hasNoQuizzes          = @assignmentView.collection.length +
                                       @openView.collection.length == 0
      @options.hasAssignmentQuizzes  = @assignmentView.collection.length > 0
      @options.hasOpenQuizzes        = @openView.collection.length > 0
      @options.hasSurveys            = @surveyView.collection.length > 0

    collections: ->
      [
        @options.assignmentView.collection
        @options.openView.collection
        @options.surveyView.collection
      ]

    keyUpSearch: =>
      clearTimeout @onInputTimer
      @onInputTimer = setTimeout @filterResults, 200

    filterResults: =>
      term = $('#searchTerm').val()

      _.each @collections(), (collection) =>
        collection.each (model) =>
          model.set('hidden', !@filter(model, term))

    filter: (model, term) =>
      return true unless term
      regex = new RegExp(term, 'ig')
      model.get('title').match(regex)
