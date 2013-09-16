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
      @model.save 'groupId', null

    attach: ->
      @model.on 'change', @render, this

    afterRender: ->
      @$el.data('model', @model)

    toJSON: ->
      _.extend {}, this, super

