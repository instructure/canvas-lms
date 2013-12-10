define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupUserView'
  'jst/groups/manage/groupUsers'
  'jqueryui/draggable'
  'jqueryui/droppable'
], (_, PaginatedCollectionView, GroupUserView, template) ->

  class GroupUsersView extends PaginatedCollectionView

    @optionProperty 'group'

    defaults: _.extend {},
      PaginatedCollectionView::defaults,
      itemView: GroupUserView
      itemViewOptions:
        canAssignToGroup: false
        canRemoveFromGroup: true

    dragOptions:
      helper: 'clone'
      opacity: 0.75
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
      @group.on 'change:members_count', @render
      @collection.on 'moved', @highlightUser

    highlightUser: (user) ->
      user.itemView.highlight()

    toJSON: ->
      count: @group.usersCount()

    renderItem: (model) =>
      super
      @_initDrag(model.view)

    ##
    # enable draggable on the child GroupUserView (view)
    _initDrag: (view) =>
      view.$el.draggable(_.extend({}, @dragOptions))

    removeItem: (model) =>
      model.view.remove()
