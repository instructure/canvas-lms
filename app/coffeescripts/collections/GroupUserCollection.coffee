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
      ##
      # handle incrementing before removing/adding
      #   in order to have correct counts for entities
      #   listening to collection related events
      @increment -1
      @remove model
      if other = @groupUsersFor(groupId)
        other.increment 1
        other.add model if other?.loaded

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
