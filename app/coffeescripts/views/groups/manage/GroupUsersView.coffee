define [
  'jquery'
  'underscore'
  'compiled/collections/GroupCollection'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupUserView'
  'compiled/views/groups/manage/EditGroupAssignmentView'
  'compiled/views/groups/manage/GroupCategoryCloneView'
  'jst/groups/manage/groupUsers'
  'jqueryui/draggable'
  'jqueryui/droppable'
], ($, _, GroupCollection, PaginatedCollectionView, GroupUserView, EditGroupAssignmentView, GroupCategoryCloneView, template) ->

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
        $('.assign-to-group-menu').hide()

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    template: template

    attach: ->
      @model.on 'change:members_count', @render
      @model.on 'change:leader', @render
      @collection.on 'moved', @highlightUser

    highlightUser: (user) ->
      user.itemView.highlight()

    closeMenus: ->
      for model in @collection.models
        model.itemView.closeMenu()

    events:
      'click .remove-from-group': 'removeUserFromGroup'
      'click .remove-as-leader': 'removeLeader'
      'click .set-as-leader': 'setLeader'
      'click .edit-group-assignment': 'editGroupAssignment'

    removeUserFromGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      user = @collection.get($target.data('user-id'))

      if @model.get("has_submission")
        @cloneCategoryView = new GroupCategoryCloneView
          model: @model.collection.category,
          openedFromCaution: true
        @cloneCategoryView.open()
        @cloneCategoryView.on "close", =>
          if @cloneCategoryView.cloneSuccess
            window.location.reload()
          else if @cloneCategoryView.changeGroups
            @moveUser(e, $target)
          else
            $("#group-#{@model.id}-user-#{user.id}-actions").focus()
      else
        @moveUser(e, $target)

    moveUser: (e, $target) ->
      $target.prev().focus()
      @collection.get($target.data('user-id')).save 'group', null

    removeLeader: (e) ->
      e.preventDefault()
      e.stopPropagation()
      @model.save(leader: null)

    setLeader: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @model.save(leader: {id: $target.data('user-id').toString()})

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
      locked: @model.isLocked()
      ENV: ENV

    renderItem: (model) =>
      super
      @_initDrag(model.view) unless @model?.isLocked()

    ##
    # enable draggable on the child GroupUserView (view)
    _initDrag: (view) =>
      view.$el.draggable(_.extend({}, @dragOptions))
      view.$el.on 'dragstart', (event, ui) ->
        ui.helper.css 'width', view.$el.width()
        $(event.target).draggable 'option', 'containment', 'document'
        $(event.target).data('draggable')._setContainment()

    removeItem: (model) =>
      model.view.remove()
