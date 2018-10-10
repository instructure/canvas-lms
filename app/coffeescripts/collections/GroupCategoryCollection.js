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
  '../collections/PaginatedCollection'
  '../models/GroupCategory'
], (PaginatedCollection, GroupCategory) ->

  class GroupCategoryCollection extends PaginatedCollection
    model: GroupCategory

    @optionProperty 'markInactiveStudents'

    comparator: (category) ->
      prefix = if category.get('role') is 'uncategorized'
        '2_'
      else if category.get('protected')
        '0_'
      else
        '1_'
      prefix + category.get('name').toLowerCase()

    _defaultUrl: -> "/api/v1/group_categories"
