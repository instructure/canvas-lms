define [
  '../start_app',
  'ember',
  'ic-ajax',
  '../shared_ajax_fixtures',
  '../environment_setup',
  '../../../../behaviors/elementToggler'
], (startApp, Ember, ajax, fixtures) ->

  App = null

  module 'quizzes index integration',
    setup: ->
      fixtures.create()
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

  test 'Collapsing item groups', ->
    visit('/').then ->
      ok(find('.item-group-condensed .ig-header-title').length)
      ok(find('.item-group-condensed .ig-list').is(':visible'), 'Group starts expanded')
      click('.item-group-condensed .ig-header-title').then ->
        ok(find('.item-group-condensed .ig-list').is(':hidden'), 'Group gets collapsed')

  test 'Expanding item groups when a filter matches', ->
    visit('/').then ->
      equal(find('.quiz:visible').length, 2, 'Quiz entries are initially visible')
      click('.item-group-condensed .ig-header-title').then ->
        ok(find('.item-group-condensed .ig-list').is(':hidden'), 'Group gets collapsed')
        equal(find('.quiz:visible').length, 0, 'All quiz entries are hidden')
        fillIn('input.search-filter', 'alt').then ->
          ok(find('.item-group-condensed .ig-list').is(':visible'), 'Group gets expanded')
          equal(find('.quiz:visible').length, 1, 'Matched quiz entry becomes visible')
