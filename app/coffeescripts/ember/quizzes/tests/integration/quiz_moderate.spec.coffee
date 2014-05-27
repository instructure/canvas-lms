define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../environment_setup'
  '../../shared/environment'
], (Ember, startApp, fixtures, env) ->

  module "Quiz Moderate: Integration",

    setup: ->
      App = startApp()
      fixtures.create()

     teardown: ->
       Ember.run App, 'destroy'

  test 'redirect non-permissioned users to quiz.show', ->
    env.setEnv
      PERMISSIONS:
        manage: false
        update: false

    visit('/1/moderate')
    andThen ->
      wait().then ->
        # this can change to currentRoute() once we update ember >= 1.5.0
        currentRoute = App.__container__.lookup('controller:application').get('currentRouteName')
        equal currentRoute, 'quiz.show'

  test 'permissioned users should see moderate page', ->
    env.setEnv
      PERMISSIONS:
        manage: true
        update: true

    visit('/1/moderate')
    andThen ->
      wait().then ->
        # this can change to currentRoute() once we update ember >= 1.5.0
        currentRoute = App.__container__.lookup('controller:application').get('currentRouteName')
        equal currentRoute, 'quiz.moderate'
