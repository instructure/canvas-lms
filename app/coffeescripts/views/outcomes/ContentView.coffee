define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomeView'
  'compiled/views/outcomes/OutcomeGroupView'
], ($, _, Backbone, Outcome, OutcomeGroup, OutcomeView, OutcomeGroupView) ->

  # This view is a wrapper for showing details for outcomes and groups.
  # It uses OutcomeView and OutcomeGroupView to render
  class ContentView extends Backbone.View

    initialize: ({@readOnly, @instructionsTemplate}) ->
      @render()

    # accepts: Outcome and OutcomeGroup
    show: (model) =>
      return if model?.isNew()
      @_show model: model

    # accepts: Outcome and OutcomeGroup
    add: (model) =>
      @_show model: model, state: 'add'
      @trigger 'adding'
      @innerView.on 'addSuccess', => @trigger 'addSuccess'

    # private
    _show: (viewOpts) ->
      viewOpts = _.extend {}, viewOpts, readOnly: @readOnly
      @innerView?.remove()
      @innerView =
        if viewOpts.model instanceof Outcome
          new OutcomeView viewOpts
        else if viewOpts.model instanceof OutcomeGroup
          new OutcomeGroupView viewOpts
      @render()

    render: ->
      @$el.html if @innerView
          @innerView.render().el
        else
          @instructionsTemplate()
      this

    remove: ->
      @innerView?.off 'addSuccess'