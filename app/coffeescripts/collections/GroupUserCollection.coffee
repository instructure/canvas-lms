define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupUser'
], (PaginatedCollection, GroupUser) ->

  class GroupUserCollection extends PaginatedCollection

    model: GroupUser
    comparator: (user) -> user.get('sortable_name').toLowerCase()

    @optionProperty 'groupId'

    initialize: (models) ->
      super
      @loaded = @loadedAll = models?
      @on 'change:groupId', @updateGroupId
      @model = GroupUser.extend defaults: {@groupId}

    load: (target = 'all') ->
      @loadAll = target is 'all'
      @loaded = true
      @fetch() if target isnt 'none'
      @load = ->

    updateGroupId: (model, groupId) =>
      @remove model
      @increment -1
      if other = @groupUsersFor(groupId)
        other.add model if other?.loaded
        other.increment 1

    increment: (amount) ->
      if @group
        @group.increment 'members_count', amount
      else if @category # unassigned collection
        @category.increment 'unassigned_users_count', amount

    getCategory: ->
      if @group
        @group.collection.category
      else if @category
        @category

    groupUsersFor: (id) ->
      category = @getCategory()
      if id?
        category?._groups?.get(id)?._users
      else
        category?._unassignedUsers
