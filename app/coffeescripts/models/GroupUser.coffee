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
      if previousGroupId and (not groupId? or @get('category').get('allows_multiple_memberships'))
        @leaveGroup(previousGroupId)

    # creating membership will delete pre-existing membership in same group category
    joinGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/memberships", 'POST', {user_id: @get('id')},
        (data) => @trigger('ajaxJoinGroupSuccess', data)

    leaveGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/users/#{@get('id')}", 'DELETE'

    # e.g. so the view can give the user an indication of what happened
    # once everything is done
    moved: =>
      @trigger 'moved', this
