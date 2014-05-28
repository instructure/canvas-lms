define [
  'ember'
  '../shared/environment'
], (Ember, env) ->

  QuizzesRoute = Ember.Route.extend

    activate: ->
      $("body").addClass("with_item_groups")

    deactivate: ->
      $("body").removeClass("with_item_groups")

    model: (params) ->
      @store.find('quiz').then (quizzes) =>
        perms = env.get 'env.PERMISSIONS'
        perms.create = @store.metadataFor('quiz').permissions.quizzes.create
        env.set 'env.PERMISSIONS', perms
        quizzes

