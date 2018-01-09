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
  '../collections/GroupUserCollection'
  '../models/GroupUser'
], (GroupUserCollection, GroupUser) ->

  class UnassignedGroupUserCollection extends GroupUserCollection

    url: ->
      _url = "/api/v1/group_categories/#{@category.id}/users?per_page=50&include[]=sections&exclude[]=pseudonym"
      _url += "&unassigned=true&include[]=group_submissions" unless @category.get('allows_multiple_memberships')
      @url = _url

    # don't add/remove people in the "Everyone" collection (this collection)
    # if the category supports multiple memberships
    membershipsLocked: ->
      @category.get('allows_multiple_memberships')

    increment: (amount) ->
      @category.increment 'unassigned_users_count', amount

    search: (filter, options) ->
      options = options || {}
      options.reset = true

      if filter && filter.length >= 3
        options.url = @url + "&search_term=" + filter
        @filtered = true
        return @fetch(options)
      else if @filtered
        @filtered = false
        options.url = @url
        return @fetch(options)

      # do nothing
