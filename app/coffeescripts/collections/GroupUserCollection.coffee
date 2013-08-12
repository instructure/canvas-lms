define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupUser'
], (PaginatedCollection, GroupUser) ->

  class GroupUserCollection extends PaginatedCollection

    model: GroupUser
    comparator: (user) -> user.get('sortable_name').toLowerCase()

    @collectionMap = {}

    @optionProperty 'groupId'

    initialize: (models) ->
      super
      @loaded = @loadedAll = models?
      @on 'fetched:last', => @loadedAll = true
      @on 'change:groupId', @updateGroupId
      GroupUserCollection.collectionMap[@groupId] = this
      @model = GroupUser.extend defaults: {@groupId}

    load: (target = 'all') ->
      @loadAll = target is 'all'
      @loaded = true
      @fetch() if target isnt 'none'
      @load = ->

    updateGroupId: (model, groupId) =>
      @remove model
      @group?.decrement('members_count')
      if other = GroupUserCollection.collectionMap[groupId]
        other.add model if other?.loaded
        other.group?.increment('members_count')

