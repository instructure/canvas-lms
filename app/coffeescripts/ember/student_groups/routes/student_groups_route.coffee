define ['ember'], (Ember) ->

  StudentGroupsRoute = Ember.Route.extend

    actions:
      # TODO: Create a DialogRoute that has this action.
      _destroyModal: ->
        @disconnectOutlet
          outlet: 'modal'
          parentView: 'application'

      newGroup: ->
        @render 'new_group',
          into: 'application'
          outlet: 'modal'
          theParent: @controller
