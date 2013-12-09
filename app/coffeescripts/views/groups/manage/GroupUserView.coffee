define [
  'underscore'
  'Backbone'
  'jst/groups/manage/groupUser'
], (_, {View}, template) ->

  class GroupUserView extends View

    @optionProperty 'canAssignToGroup'
    @optionProperty 'canRemoveFromGroup'

    tagName: 'li'

    className: 'group-user'

    template: template

    events:
      'click .remove-from-group': 'removeUserFromGroup'

    removeUserFromGroup: (e)->
      e.preventDefault()
      e.stopPropagation()
      @model.moveTo null

    attach: ->
      @model.on 'change', @render, this

    afterRender: ->
      @$el.data('model', @model)

    highlight: ->
      @$el.addClass 'group-user-highlight'
      setTimeout =>
        @$el.removeClass 'group-user-highlight'
      , 1000

    toJSON: ->
      _.extend {}, this, super

