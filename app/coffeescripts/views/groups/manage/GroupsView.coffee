define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/GroupDetailView'
  'compiled/views/Filterable'
  'jst/groups/manage/groups'
], (_, PaginatedCollectionView, GroupView, GroupUsersView, GroupDetailView, Filterable, template) ->

  class GroupsView extends PaginatedCollectionView

    @mixin Filterable

    template: template

    els: _.extend {}, # override Filterable's els, since our filter is in another view
      PaginatedCollectionView::els
      '.no-results': '$noResults'

    afterRender: ->
      @$filter = @$externalFilter
      super

    dropOptions:
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    createItemView: (model) ->
      groupUsersView = new GroupUsersView {group: model, collection: model.users()}
      groupDetailView = new GroupDetailView {group: model, users: model.users()}
      new GroupView {model, groupUsersView, groupDetailView, addUnassignedMenu: @options.addUnassignedMenu}

    renderItem: (model) ->
      super
      # enable droppable on the child GroupView (view)
      model.view.$el.droppable(_.extend({}, @dropOptions))
                    .on('drop', @_onDrop)

    ##
    # handle drop events on a GroupView
    # e - Event object.
    #   e.currentTarget - group the user is dropped on
    # ui - jQuery UI object.
    #   ui.draggable - the user being dragged
    _onDrop: (e, ui) =>
      user = ui.draggable.data('model')
      newGroupId = $(e.currentTarget).data('id')
      setTimeout ->
        user.save({'groupId': newGroupId})
