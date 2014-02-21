define [
  'ember'
], (Ember) ->

  QuizRoute = Ember.Route.extend

    actions:
      # TODO: Create a DialogRoute that has this action.
      _destroyModal: ->
        @disconnectOutlet
          outlet: 'modal'
          parentView: 'application'

      confirmDeletion: ->
        @render 'confirm_delete',
          into: 'application'
          outlet: 'modal'

      messageStudents: ->
        @render 'message_students',
          into: 'application'
          outlet: 'modal'
