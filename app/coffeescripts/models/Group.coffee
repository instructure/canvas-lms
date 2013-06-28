#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'Backbone'
  'compiled/collections/GroupUserCollection'
], ({Model}, GroupUserCollection) ->

  class Group extends Model
    modelType: 'group'
    resourceName: 'groups'

    users: ->
      @_users = new GroupUserCollection(null, groupId: @id)
      @_users.group = this
      @_users.url = "/api/v1/groups/#{@id}/users?per_page=50"
      @users = -> @_users
      @_users

    usersCount: ->
      if @_users?.loadedAll
        @_users.length
      else
        @get('members_count')

    url: ->
      "/api/v1/groups/#{@id}"
