define [
  'ember'
  '../shared/environment',
  'i18n!quizzes_route',
  '../shared/title_builder',
  '../models/quiz'
], (Ember, env, I18n, titleBuilder, Quiz) ->

  QuizzesRoute = Ember.Route.extend

    activate: ->
      $("body").addClass("with_item_groups")

    deactivate: ->
      $("body").removeClass("with_item_groups")

    model: (params) ->
      quizRecordsArray = @store.find('quiz')
      quizRecordsArray.then (quizzes) =>
        perms = env.get 'env.PERMISSIONS'
        perms.create = @store.metadataFor('quiz').permissions.quizzes.create
        env.set 'env.PERMISSIONS', perms
        this.store.adapterFor(Quiz).loadRemainingPages(@store)
        quizzes
      quizRecordsArray

    afterModel: ->
      title = I18n.t('quizzes_route_title', 'Quizzes')
      titleBuilder([title])
