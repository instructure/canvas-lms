define [
  'compiled/models/User'
  'jquery.ajaxJSON'
], (User) ->

  class GroupUser extends User

    ##
    # janky sync override cuz we don't have the luxury of (ember data || backbone-relational)
    sync: (method, model, options) =>
      groupId = @get('groupId')
      # return unless changing groupId
      return if groupId is @previous('groupId')
      # if the user is joining another group
      if groupId?
        @joinGroup(groupId)
      # else if the user is being unassigned and is not currently unassigned
      else if previousGroupId = @previous('groupId')
        @leaveGroup(previousGroupId)

    # creating membership will delete pre-existing membership in same group category
    joinGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/memberships", 'POST', {user_id: @get('id')}

    leaveGroup: (groupId) ->
      $.ajaxJSON "/api/v1/groups/#{groupId}/users/#{@get('id')}", 'DELETE'
