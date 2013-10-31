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
      @removeUser model
      if other = @groupUsersFor(groupId)
        other.addUser model

    # don't add/remove people in the everyone collection if the category
    # supports multiple memberships
    membershipsLocked: ->
      not @groupId? and @category?.get('allows_multiple_memberships')

    addUser: (user) ->
      if existingUser = @get(user)
        user = existingUser
      else if not @membershipsLocked()
        @increment 1
        @add user if @loaded
      user.moved() if @loaded # e.g. so view can highlight it

    removeUser: (user) ->
      return if @membershipsLocked()
      @increment -1
      @remove user if @loaded

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
      @getCategory()?.groupUsersFor(id)

