//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import $ from 'jquery'

import PaginatedCollection from '../collections/PaginatedCollection'
import Group from '../models/Group'
import natcompare from '../util/natcompare'

export default class ContextGroupCollection extends PaginatedCollection {
  comparator = (x, y) =>
    natcompare.by(g => g.get('group_category').name)(x, y) ||
    natcompare.by(g => g.get('name'))(x, y)

  url() {
    const url_base = `/api/v1/courses/${this.options.course_id}/groups?`
    const params = {
      include: ['users', 'group_category', 'permissions'],
      include_inactive_users: 'true'
    }
    return url_base + $.param(params)
  }
}
ContextGroupCollection.prototype.model = Group

ContextGroupCollection.optionProperty('course_id')
