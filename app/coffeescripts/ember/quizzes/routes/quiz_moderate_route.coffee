define [
  'ember'
  '../mixins/redirect'
  '../shared/environment'
], (Em, Redirect, env) ->

  ModerateRoute = Em.Route.extend Redirect,

    beforeModel: (transition) ->
      @validateRoute('canManage', 'quiz.show')

    model: ->
      @combinedUsersSubmissionsPromise()

    combinedUsersSubmissionsPromise: ->
      quiz = @modelFor('quiz')
      _this = this
      quiz.get('studentQuizSubmissions').then (quizSubmissions) ->
        quizSubmissions ||= []
        quiz.get('users').then (users) ->
          _this.combineModels(users, quizSubmissions)

    combineModels: (users, quizSubmissions) ->
      userSubHash = @createSubHash(quizSubmissions)
      users.forEach (user) ->
        quizSubmission = userSubHash[user.get('id')] || Ember.Object.create()
        user.set('quizSubmission', quizSubmission)
      users

    createSubHash: (submissions) ->
      hash = {}
      submissions.forEach (sub) ->
        id = sub.get('user.id')
        hash[id] = sub
      hash

    forceReload: (quiz) ->
      resolver = Em.RSVP.defer()
      resolver.resolve = (promise) =>
        promise.then =>
          Ember.run.later this, (->
            @controllerFor('quiz.moderate').set('reloading', false)
          ), 500
          @combinedUsersSubmissionsPromise().then (models) =>
            @get('controller').set('content', models)
      relationship = quiz.constructor.metaForProperty('studentQuizSubmissions')
      link = quiz.get('links.studentQuizSubmissions')
      @store.findHasMany(quiz, link, relationship, resolver)

    actions:
      refreshData: ->
        quiz = @modelFor('quiz')
        @forceReload(quiz)

  ModerateRoute
