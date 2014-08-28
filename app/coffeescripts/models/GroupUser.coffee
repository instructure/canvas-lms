define [
  'jquery'
  'compiled/models/User'
  'jquery.ajaxJSON'
], ($, User) ->

  class GroupUser extends User

    ##
    # janky sync override cuz we don't have the luxury of (ember data || backbone-relational)
    sync: (method, model, options) =>
      group = @get('group')
      previousGroup = @previous('group')
      # return unless changing group
      return if group is previousGroup
      # if the user is joining another group
      if group?
        @joinGroup(group)
      # if the user is being removed from a group, or is being moved to
      # another group AND the category allows multiple memberships (in
      # which case rails won't delete the old membership, so we have to)
      if previousGroup and (not group? or @get('category').get('allows_multiple_memberships'))
        @leaveGroup(previousGroup)

    # creating membership will delete pre-existing membership in same group category
    joinGroup: (group) ->
      $.ajaxJSON "/api/v1/groups/#{group.id}/memberships", 'POST', {user_id: @get('id')},
        (data) => @trigger('ajaxJoinGroupSuccess', data)

    leaveGroup: (group) ->
      $.ajaxJSON "/api/v1/groups/#{group.id}/users/#{@get('id')}", 'DELETE'

    # e.g. so the view can give the user an indication of what happened
    # once everything is done
    moved: =>
      @trigger 'moved', this
