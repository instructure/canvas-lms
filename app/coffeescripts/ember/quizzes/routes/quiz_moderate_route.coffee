define [
  'ember'
  '../mixins/redirect'
], (Em, Redirect) ->

  Em.Route.extend Redirect,

    beforeModel: (transition) ->
      @validateRoute('canManage', 'quiz.show')

    model: ->
      @modelFor 'quiz'
