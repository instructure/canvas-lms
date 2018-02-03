#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'jquery',
  '../collections/PaginatedCollection'
  '../collections/GroupUserCollection'
  '../models/Group'
  '../util/natcompare'
], ($, PaginatedCollection, GroupUserCollection, Group, natcompare) ->

  class ContextGroupCollection extends PaginatedCollection
    model: Group
    comparator: (x, y) =>
      natcompare.by((g) -> g.get('group_category')['name'])(x, y) ||
      natcompare.by((g) -> g.get('name'))(x, y)

    @optionProperty 'course_id'

    url: ->
      url_base = "/api/v1/courses/#{@options.course_id}/groups?"
      params = {
        include: ['users', 'group_category', 'permissions']
        include_inactive_users: 'true'
      }
      url_base + $.param(params)
