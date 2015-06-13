define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/quizzes/QuizItemGroupView'
  'jst/quizzes/IndexView'
], ($, _, Backbone, QuizItemGroupView, template) ->

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
    , 200

    filterResults: =>
      _.each @views(), (view) =>
        view.filterResults($('#searchTerm').val())
