define [
  'ember'
  '../mixins/redirect'
  '../shared/environment'
  'ic-ajax'
], (Em, Redirect, env, ajax) ->

  ModerateRoute = Em.Route.extend Redirect,

    beforeModel: (transition) ->
      @validateRoute('canManage', 'quiz.show')

    model: ->
      quiz = @modelFor('quiz')
      quizSubmissions = quiz.get('quizSubmissions')
      _this = this
      quizSubmissions.then ->
        users = quiz.get('users')
        users.then ->
          userSubHash = _this.createSubHash(quizSubmissions.get('content'))
          fakes = []
          users.get('content').forEach (user) ->
            quizSubmission = userSubHash[user.get('id')] || Ember.Object.create()
            user.set('quizSubmission', quizSubmission)

    createSubHash: (submissions) ->
      hash = {}
      submissions.forEach (sub) ->
        id = sub.get('user.id')
        hash[id] = sub
      hash

  ModerateRoute
