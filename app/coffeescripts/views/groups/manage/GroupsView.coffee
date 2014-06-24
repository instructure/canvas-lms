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

    events: _.extend {},
      PaginatedCollectionView::events
      'scroll': 'closeMenus'
      'dragstart': 'closeMenus'

    closeMenus: _.throttle ->
      for model in @collection.models
        model.itemView.closeMenus()
    , 50

    attach: ->
      @collection.on 'change', @reorder

    afterRender: ->
      @$filter = @$externalFilter
      super

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    createItemView: (group) ->
      groupUsersView = new GroupUsersView {model: group, collection: group.users(), itemViewOptions: {canEditGroupAssignment: not group.isLocked()}}
      groupDetailView = new GroupDetailView {model: group, users: group.users()}
      groupView = new GroupView {model: group, groupUsersView, groupDetailView, addUnassignedMenu: @options.addUnassignedMenu}
      group.itemView = groupView

    updateDetails: ->
      for model in @collection.models
        model.itemView.updateFullState()
