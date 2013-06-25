define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupView'
  'compiled/views/Filterable'
  'jst/groups/manage/groups'
], (_, PaginatedCollectionView, GroupView, Filterable, template) ->

  class GroupsView extends PaginatedCollectionView

    @mixin Filterable

    initialize: (options) ->
      super _.extend {}, options,
        itemView: GroupView
