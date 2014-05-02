define [
  'ember'
  'underscore'
  '../mixins/redirect'
], (Ember, _, Redirect) ->

  {RSVP} = Ember

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

    afterModel: ->
      # for some reason, the quiz is not associating with the quiz_questions,
      # although the inverse is true (quiz questions *are* associated to the quiz),
      # anyway, do it manually:
      set = @modelFor('quizStatistics').get('questionStatistics')
      set.clear()
      set.pushObjects(@store.all('questionStatistics'))
