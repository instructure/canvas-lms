define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupView'
  'jst/groups/manage/groups'
], (_, PaginatedCollectionView, GroupView, template) ->

  class GroupsView extends PaginatedCollectionView

    initialize: (options) ->
      super _.extend {}, options,
        itemView: GroupView
