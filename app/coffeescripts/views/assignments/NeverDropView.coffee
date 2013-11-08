define [
  'Backbone'
  'underscore'
  'jst/assignments/NeverDrop'
], (Backbone, _, neverDropTemplate) ->

  class NeverDrop extends Backbone.View
    className: 'never_drop_rule'
    template: neverDropTemplate

    events:
      'change select': 'setChosen'
      'click .remove_never_drop': 'removeNeverDrop'

    # change the `chosen_id` on a model
    # and mark it for focusing when we re-render
    # the collection
    setChosen: (e) ->
      $target = @$(e.currentTarget)
      @model.set
        'chosen_id': $target.val()
        'focus': true

    removeNeverDrop: (e) ->
      e.preventDefault()
      @model.collection.remove @model

    #after render we want to check and see if we should focus
    #this select
    afterRender: ->
      if @model.has('focus')
        _.defer(=>
          @$('select').focus()
          @model.unset 'focus'
        )

    toJSON: =>
      json = super
      if @model.has('chosen_id')
        json.assignments = @model.collection.toAssignments(@model.get('chosen_id'))
      json
