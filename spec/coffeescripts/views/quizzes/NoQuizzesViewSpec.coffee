define [
  'Backbone'
  'compiled/views/quizzes/NoQuizzesView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, NoQuizzesView, $) ->

  module 'NoQuizzesView',
    setup: ->
      @view = new NoQuizzesView()

  test 'it renders', ->
    ok @view.$el.hasClass('item-group-condensed')