define [
  'compiled/models/User'
  'jquery.ajaxJSON'
], (User) ->

  class GroupUser extends User

    ##
    # janky sync override cuz we don't have the luxury of (ember data || backbone-relational)
    sync: (method, model, options) =>
      groupId = @get('groupId')
      previousGroupId = @previous('groupId')
      # return unless changing groupId
      return if groupId is previousGroupId
      # if the user is joining another group
      if groupId?
        @joinGroup(groupId)
      # if the user is being removed from a group, or is being moved to
      # another group AND the category allows multiple memberships (in
      # which case rails won't delete the old membership, so we have to)
      if previousGroupId and (not groupId? or @category?.get('allows_multiple_memberships'))
        @leaveGroup(previousGroupId)

    # creating membership will delete pre-existing membership in same group category
    joinGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/memberships", 'POST', {user_id: @get('id')}, @addToCollectionIfCopy

    # when moving (not copying) a user, the collections will ensure it's
    # added/removed correctly to/from them. in the case of copying, otoh,
    # the user is not yet in any collection (and so no reassignment
    # happens), so we manage that logic here
    addToCollectionIfCopy: (data) =>
      return unless @copy
      return unless groupUsers = @category.groupUsersFor(@get('groupId'))
      delete @copy

      if data.just_created
        groupUsers.addUser this
      else # user was already in this group
        groupUsers.get(@id)?.moved()

    leaveGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/users/#{@get('id')}", 'DELETE'

    # e.g. so the view can give the user an indication of what happened
    # once everything is done
    moved: =>
      @trigger 'moved', this

    moveTo: (newGroupId) ->
      groupId = @get('groupId')
      category = @collection?.getCategory?()
      return if groupId is newGroupId

      model = this
      # if we're in the Unassigned/Everyone collection, and the category
      # allows multiple memberships, don't actually move this, move a copy
      # instead
      if not groupId? and category?.get('allows_multiple_memberships')
        model = model.clone()
        model.copy = true
      model.category = category
      model.save groupId: newGroupId
