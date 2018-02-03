#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  '../models/User'
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
