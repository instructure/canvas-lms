define [
  'compiled/models/User'
  'jquery.ajaxJSON'
], (User) ->

  class GroupUser extends User

    defaults:
      groupId: null
      previousGroupId: null

    initialize: ->
      @on 'change:groupId', @updatePreviousGroupId

    # creating membership will delete pre-existing membership in same group category
    joinGroup: (groupId) ->
      $.ajaxJSON @createMembershipUrl(groupId), 'POST', {user_id: @get('id')}

    leavePreviousGroup: ->
      $.ajaxJSON @deleteMembershipUrl(@get('previousGroupId'), @get('id')), 'DELETE'

    sync: (method, model, options) =>
      groupId = model.get('groupId')
      if groupId is null
        @leavePreviousGroup()
      else
        @joinGroup(groupId)

    updatePreviousGroupId: ->
      @set 'previousGroupId', @previous('groupId')

    createMembershipUrl: (groupId) ->
      "/api/v1/groups/#{groupId}/memberships"

    deleteMembershipUrl: (groupId, userId) ->
      "/api/v1/groups/#{groupId}/users/#{userId}"