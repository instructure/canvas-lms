define [ 'ember', '../mixins/redirect' ], (Ember, Redirect) ->
  Ember.Route.extend Redirect,
    beforeModel: (transition) ->
      @validateRoute('canManage', 'quiz.show')

    model: (transition, options) ->
      quiz = @modelFor('quiz')
      quiz.get('quizStatistics').then((items)->
        # use the latest statistics report available:
        items.sortBy('createdAt').get('lastObject')
      ).then (latestStatistics)->
        # load the reports, we need these to be able to generate if requested
        quiz.get('quizReports').then ->
          latestStatistics

    actions:
      showDiscriminationIndexHelp: ->
        @render 'quiz/statistics/questions/multiple_choice/discrimination_index_help',
          into: 'application'
          outlet: 'modal'
