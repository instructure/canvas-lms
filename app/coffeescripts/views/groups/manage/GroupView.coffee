define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/groups/manage/group'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/GroupDetailView'
  'compiled/behaviors/firefox_number_fix'
], ($, _, {View}, template, GroupUsersView, GroupDetailView) ->

  class GroupView extends View

    tagName: 'li'

    className: 'group'

    attributes: ->
      "data-id": @model.id

    template: template

    @optionProperty 'expanded'

    @optionProperty 'addUnassignedMenu'

    @child 'groupUsersView', '[data-view=groupUsers]'
    @child 'groupDetailView', '[data-view=groupDetail]'

    events:
      'click .toggle-group': 'toggleDetails'
      'click .add-user': 'showAddUser'
      'focus .add-user': 'showAddUser'
      'blur .add-user': 'hideAddUser'

    dropOptions:
      accept: '.group-user'
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    attach: ->
      @expanded = false
      @users = @model.users()
      @model.on 'destroy', @remove, this
      @model.on 'change:members_count', @updateFullState, this
      @model.on 'change:max_membership', @updateFullState, this

    afterRender: ->
      @$el.toggleClass 'group-expanded', @expanded
      @$el.toggleClass 'group-collapsed', !@expanded
      @groupDetailView.$toggleGroup.attr 'aria-expanded', '' + @expanded
      @updateFullState()

    updateFullState: ->
      return if @model.isLocked()
      if @model.isFull()
        @$el.droppable("destroy") if @$el.data('droppable')
        @$el.addClass('slots-full')
      else
        # enable droppable on the child GroupView (view)
        if !@$el.data('droppable')
          @$el.droppable(_.extend({}, @dropOptions))
            .on('drop', @_onDrop)
        @$el.removeClass('slots-full')

    toggleDetails: (e) ->
      e.preventDefault()
      @expanded = not @expanded
      if @expanded and not @users.loaded
        @users.load(if @model.usersCount() then 'all' else 'none')
      @afterRender()

    showAddUser: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @addUnassignedMenu.group = @model
      @addUnassignedMenu.showBy $target, e.type is 'click'

    hideAddUser: (e) ->
      @addUnassignedMenu.hide()

    closeMenus: ->
      @groupDetailView.closeMenu()
      @groupUsersView.closeMenus()

    ##
    # handle drop events on a GroupView
    # e - Event object.
    #   e.currentTarget - group the user is dropped on
    # ui - jQuery UI object.
    #   ui.draggable - the user being dragged
    _onDrop: (e, ui) =>
      user = ui.draggable.data('model')
      newGroupId = $(e.currentTarget).data('id')
      setTimeout =>
        @model.collection.category.reassignUser(user, @model.collection.get(newGroupId))
