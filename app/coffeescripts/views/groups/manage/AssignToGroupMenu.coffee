define [
  'compiled/views/groups/manage/PopoverMenuView'
  'compiled/models/GroupUser'
  'jst/groups/manage/assignToGroupMenu'
  'underscore'
  'compiled/jquery/outerclick'
], (PopoverMenuView, GroupUser, template, _) ->

  class AssignToGroupMenu extends PopoverMenuView

    events: _.extend {},
      PopoverMenuView::events,
      'click .set-group': 'setGroup'

    attach: ->
      @collection.on 'change add remove reset', @render

    tagName: 'div'

    className: 'assign-to-group-menu ui-tooltip popover content-top horizontal'

    template: template

    setGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      newGroupId = $(e.currentTarget).data('group-id')
      @model.moveTo newGroupId
      @hide()

    toJSON: ->
      hasGroups = @collection.length > 0
      {
        groups: @collection.toJSON()
        noGroups: !hasGroups
        allFull: =>
          hasGroups && @collection.models.filter (g)->
            !g.isFull()
          .length == 0
      }
