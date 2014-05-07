define [
  'ember'
], (Em) ->

  QuizModerateController = Em.ArrayController.extend

    headerChecked: false
    reloading: false

    actions:
      editSubmissionUser: (su) ->
        Em.K # noop for now

      refreshData: ->
        @set('reloading', true)
        true

  QuizModerateController
