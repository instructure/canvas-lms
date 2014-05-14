define [
  'ember'
  '../shared/environment'
], (Ember, env) ->

  QuizzesRoute = Ember.Route.extend

    model: (params) ->
      @store.find('quiz').then (quizzes) =>
        perms = env.get 'env.PERMISSIONS'
        perms.create = @store.metadataFor('quiz').permissions.quizzes.create
        env.set 'env.PERMISSIONS', perms
        quizzes

