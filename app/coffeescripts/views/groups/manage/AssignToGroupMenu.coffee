define [
  'Backbone'
  'jst/groups/manage/assignToGroupMenu'
], ({View}, template) ->

  class AssignToGroupMenu extends View

    initialize: ->
      super
      @render()
      $body = $(document.body)
      $body.on 'click', @hide
      @$el.appendTo $body
      @$el.hide()
      @collection.on 'change add remove reset', @render

    events:
      'click .set-group': 'setGroup'

    tagName: 'div'

    className: 'assign-to-group-menu popover content-top horizontal'

    template: template

    showBy: ($target) ->
      @render()
      @$el.show()
      @$el.position
        my: 'left+6 top-47'
        at: 'right center'
        of: $target

    hide: =>
      @$el.hide()

    setGroup: (e) ->
      e.preventDefault()
      @model.set 'groupId', $(e.target).data('group-id')
      @hide()

    toJSON: -> groups: @collection.toJSON()
