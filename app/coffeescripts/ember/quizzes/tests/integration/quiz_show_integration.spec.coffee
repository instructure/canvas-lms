define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
  '../environment_setup'
], (Ember, startApp, fixtures) ->
  App = null

  QUIZ = fixtures.QUIZZES[0]
  ASSIGNMENT_GROUP = {fixtures}

  module "Quiz Show Integration",

    setup: ->
      App = startApp()
      fixtures.create()

     teardown: ->
       Ember.run App, 'destroy'

  testShowPage = (desc, callback) ->
    test desc, ->
      visit('/1').then callback

  testShowPage 'shows attributes', ->
    html = find('#quiz-show').html()

    htmlHas = (matchingHTML, desc) ->
      ok html.match(matchingHTML), "shows #{desc}"

    ok html.indexOf(QUIZ.description) != -1, "doesn't escape server-sanitized HTML"
    htmlHas QUIZ.title, "quiz title"
    htmlHas QUIZ.points_possible, "points possible"

  testShowPage 'shows assignment group', ->
    text = find('#quiz-show').text()
    ok text.match ASSIGNMENT_GROUP.name
