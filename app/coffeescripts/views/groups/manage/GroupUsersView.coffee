define [
  'underscore'
  'compiled/collections/GroupCollection'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupUserView'
  'compiled/views/groups/manage/EditGroupAssignmentView'
  'jst/groups/manage/groupUsers'
  'jqueryui/draggable'
  'jqueryui/droppable'
], (_, GroupCollection, PaginatedCollectionView, GroupUserView, EditGroupAssignmentView, template) ->

  class GroupUsersView extends PaginatedCollectionView

    defaults: _.extend {},
      PaginatedCollectionView::defaults,
      itemView: GroupUserView
      itemViewOptions:
        canAssignToGroup: false
        canEditGroupAssignment: true

    dragOptions:
      appendTo: 'body'
      helper: 'clone'
      opacity: 0.75
      refreshPositions: true
      revert: 'invalid'
      revertDuration: 150
      start: (event, ui) ->
        # hide AssignToGroupMenu (original and helper)
        $(event.currentTarget).find('.assign-to-group-menu').hide()
        $(ui.helper).find('.assign-to-group-menu').hide()
        $(ui.helper).width($(event.currentTarget).width())

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    template: template

    attach: ->
      @model.on 'change:members_count', @render
      @collection.on 'moved', @highlightUser

    highlightUser: (user) ->
      user.itemView.highlight()

    closeMenus: ->
      for model in @collection.models
        model.itemView.closeMenu()

    events:
      'click .remove-from-group': 'removeUserFromGroup'
      'click .edit-group-assignment': 'editGroupAssignment'

    removeUserFromGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @collection.get($target.data('user-id')).save 'groupId', null

    editGroupAssignment: (e) ->
      e.preventDefault()
      e.stopPropagation()
      # configure the dialog view with our group data
      @editGroupAssignmentView ?= new EditGroupAssignmentView
        group: @model
      # configure the dialog view with user specific model data
      $target = $(e.currentTarget)
      user = @collection.get($target.data('user-id'))
      @editGroupAssignmentView.model = user
      selector = "[data-focus-returns-to='group-#{@model.id}-user-#{user.id}-actions']"
      @editGroupAssignmentView.setTrigger selector
      @editGroupAssignmentView.open()

    toJSON: ->
      count: @model.usersCount()

    renderItem: (model) =>
      super
      @_initDrag(model.view)

    ##
    # enable draggable on the child GroupUserView (view)
    _initDrag: (view) =>
      view.$el.draggable(_.extend({}, @dragOptions))
      view.$el.on 'dragstart', (event, ui) ->
        ui.helper.css 'maxWidth', view.$el.width()

    removeItem: (model) =>
      model.view.remove()
