define [
  'compiled/views/groups/manage/PopoverMenuView'
  'compiled/views/groups/manage/AddUnassignedUsersView'
  'compiled/views/InputFilterView'
  'jst/groups/manage/addUnassignedMenu'
  'jquery'
  'underscore'
  'compiled/jquery/outerclick'
], (PopoverMenuView, AddUnassignedUsersView, InputFilterView, template, $, _) ->

  class AddUnassignedMenu extends PopoverMenuView

    @child 'usersView', '[data-view=users]'
    @child 'inputFilterView', '[data-view=inputFilter]'

    initialize: (options) ->
      @collection.setParam "per_page", 10
      options.usersView ?= new AddUnassignedUsersView {@collection}
      options.inputFilterView ?= new InputFilterView {@collection, setParamOnInvalid: true}
      @my = 'right-8 top-47'
      @at = 'left center'
      super

    className: 'add-unassigned-menu ui-tooltip popover right content-top horizontal'

    template: template

    events: _.extend {},
      PopoverMenuView::events,
      'click .assign-user-to-group': 'setGroup'

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user = @collection.getUser($target.data('user-id'))
      user.save({'group': @group})
      @hide()

    showBy: ($target, focus = false) ->
      @collection.reset()
      @collection.deleteParam 'search_term'
      super

    attach: ->
      @render()

    toJSON: ->
      users: @collection.toJSON()
      ENV: ENV

    focus: ->
      @inputFilterView.el.focus()

    setWidth: ->
      @$el.width 'auto'
