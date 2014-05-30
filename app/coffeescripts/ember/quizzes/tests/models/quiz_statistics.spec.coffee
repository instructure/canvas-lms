define [
  'ember'
  '../start_app'
  'i18n!quizzes'
], (Em, startApp, I18n) ->

  {run} = Em
  App = null
  statistics = null
  store = null

  module "Quiz",

    setup: ->
      App = startApp()
      container = App.__container__
      store = container.lookup 'store:main'
      run ->
        statistics = store.createRecord 'quiz_statistics', id: '1'

    teardown: ->
      run App, 'destroy'