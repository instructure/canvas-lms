define [
  'Backbone'
  'compiled/views/groups/manage/AddUnassignedUsersView'
  'compiled/views/InputFilterView'
  'jst/groups/manage/addUnassignedMenu'
  'compiled/jquery/outerclick'
], ({View}, AddUnassignedUsersView, InputFilterView, template) ->

  class AddUnassignedMenu extends View

    @child 'usersView', '[data-view=users]'
    @child 'inputFilterView', '[data-view=inputFilter]'

    initialize: (options) ->
      @collection.setParam "per_page", 10
      options.usersView ?= new AddUnassignedUsersView {@collection}
      options.inputFilterView ?= new InputFilterView {@collection, setParamOnInvalid: true}
      super

    className: 'add-unassigned-menu ui-tooltip popover right content-top horizontal'

    template: template

    events:
      'click': 'cancelHide'
      'click .assign-user-to-group': 'setGroup'
      'focusin': 'cancelHide'
      'focusout': 'hide'
      'outerclick': 'hide'
      'keyup': 'checkEsc'

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user = @collection.get($target.data('user-id'))
      user.save({'groupId': @groupId})
      @hide()

    attach: ->
      @render()

    toJSON: ->
      users: @collection.toJSON()

    showBy: ($target, focus = false) ->
      @cancelHide()
      @collection.reset()
      @collection.deleteParam 'search_term'
      setTimeout => # IE needs this to be async frd
        @render()
        @$el.insertAfter($target)
        @$el.show()
        @setElement @$el
        @$el.zIndex(1)
        @$el.width 'auto'
        @$el.position
          my: 'right-8 top-47'
          at: 'left center'
          of: $target
        @inputFilterView.el.focus() if focus
      , 20

    cancelHide: ->
      clearTimeout @hideTimeout

    hide: ->
      @hideTimeout = setTimeout =>
        @$el.detach()
      , 20

    checkEsc: (e) ->
      @hide() if e.keyCode is 27 # escape
