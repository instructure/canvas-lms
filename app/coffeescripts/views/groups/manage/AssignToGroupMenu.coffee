define [
  'compiled/views/groups/manage/PopoverMenuView'
  'jst/groups/manage/assignToGroupMenu'
  'underscore'
  'compiled/jquery/outerclick'
], (PopoverMenuView, template, _) ->

  class AssignToGroupMenu extends PopoverMenuView

    events: _.extend {},
      PopoverMenuView::events,
      'click .set-group': 'setGroup'

    attach: ->
      @collection.on 'change add remove reset', @render
      @render()

    tagName: 'div'

    className: 'assign-to-group-menu ui-tooltip popover content-top horizontal'

    template: template

    setGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @model.save 'groupId', $(e.currentTarget).data('group-id')
      @hide()

    toJSON: ->
      groups: @collection.toJSON()
