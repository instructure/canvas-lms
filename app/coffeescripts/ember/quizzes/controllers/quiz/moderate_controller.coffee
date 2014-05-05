define [
  'ember'
], (Em) ->

  QuizModerateController = Em.ArrayController.extend

    headerChecked: false

    actions:
      editSubmissionUser: (su) ->
        Em.K # noop for now

  QuizModerateController
