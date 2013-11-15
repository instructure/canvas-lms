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

    attach: ->
      @collection.on 'change', @reorder

    afterRender: ->
      @$filter = @$externalFilter
      super

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    createItemView: (model) ->
      groupUsersView = new GroupUsersView {group: model, collection: model.users()}
      groupDetailView = new GroupDetailView {group: model, users: model.users()}
      groupView = new GroupView {model, groupUsersView, groupDetailView, addUnassignedMenu: @options.addUnassignedMenu}
      model.itemView = groupView