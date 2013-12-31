define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../shared_ajax_fixtures',
  '../../shared/environment'
], (startApp, Ember, ajax, fixtures, environment) ->

  App = null

  window.ENV = {
    context_asset_string: 'course_1'
  }

  fixtures.create()

  module 'quizzes index integration',
    setup: ->
      App = startApp()

    teardown: ->
      Ember.run App, 'destroy'

  test 'Quizzes pages load appropriately', ->
    visit('/').then ->
      equal(find('.quiz').length, 2, 'Loads data into controller appropriately')

  test 'Filtering quizzes', ->
    visit('/').then ->
      fillIn('input.search-filter', 'alt').then ->
        equal(find('.quiz').length, 1, 'Filterings quiz works')
