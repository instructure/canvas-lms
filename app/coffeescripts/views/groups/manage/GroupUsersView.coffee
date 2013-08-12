define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupUserView'
  'jst/groups/manage/groupUsers'
], (_, PaginatedCollectionView, GroupUserView, template) ->

  class GroupUsersView extends PaginatedCollectionView

    @optionProperty 'group'

    defaults: _.extend {},
      PaginatedCollectionView::defaults,
      itemView: GroupUserView

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    template: template

    toJSON: ->
      count: @group.usersCount()
