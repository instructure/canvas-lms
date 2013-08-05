define [
  'Backbone'
  'jst/groups/manage/assignToGroupMenu'
  'compiled/jquery/outerclick'
], ({View}, template) ->

  class AssignToGroupMenu extends View

    events:
      'click': 'cancelHide'
      'click .set-group': 'setGroup'
      'focusin': 'cancelHide'
      'focusout': 'hide'
      'outerclick': 'hide'

    attach: ->
      @collection.on 'change add remove reset', @render
      @render()

    tagName: 'div'

    className: 'assign-to-group-menu popover content-top horizontal'

    template: template

    showBy: ($target) ->
      @cancelHide()
      setTimeout => # IE needs this to happen async frd
        @render()
        @$el.insertAfter($target)
        @setElement @$el
        @$el.zIndex(1)
        @$el.position
          my: 'left+6 top-47'
          at: 'right center'
          of: $target
      , 20

    cancelHide: =>
      clearTimeout @hideTimeout

    hide: =>
      @hideTimeout = setTimeout =>
        @$el.detach()
      , 20

    setGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @model.save 'groupId', $(e.currentTarget).data('group-id')
      @hide()

    toJSON: ->
      groups: @collection.toJSON()
