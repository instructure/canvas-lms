define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/Filterable'
  'jst/groups/manage/groups'
], (_, PaginatedCollectionView, GroupView, GroupUsersView, Filterable, template) ->

  class GroupsView extends PaginatedCollectionView

    @mixin Filterable

    template: template

    els: _.extend {}, # override Filterable's els, since our filter is in another view
      PaginatedCollectionView::els
      '.no-results': '$noResults'

    render: ->
      super

    afterRender: ->
      @$filter = @$externalFilter
      super

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    createItemView: (model) ->
      groupUsersView = new GroupUsersView {group: model, collection: model.users()}
      new GroupView {model, groupUsersView, addUnassignedMenu: @options.addUnassignedMenu}
