/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import Group from '../models/Group'
import natcompare from '@canvas/util/natcompare'

extend(GroupCollection, PaginatedCollection)

function GroupCollection() {
  this.fetchNext = this.fetchNext.bind(this)
  return GroupCollection.__super__.constructor.apply(this, arguments)
}

GroupCollection.prototype.model = Group

GroupCollection.prototype.comparator = natcompare.byGet('name')

GroupCollection.optionProperty('category')

GroupCollection.optionProperty('loadAll')

GroupCollection.optionProperty('markInactiveStudents')

GroupCollection.prototype._defaultUrl = function () {
  let url
  if (this.forCourse) {
    url = GroupCollection.__super__._defaultUrl.apply(this, arguments)
    if (!ENV.CAN_MANAGE_GROUPS) {
      url += '?only_own_groups=1'
    }
    return url
  } else {
    return '/api/v1/users/self/groups'
  }
}

GroupCollection.prototype.url = function () {
  if (this.category != null) {
    return (this.url = '/api/v1/group_categories/' + this.category.id + '/groups?per_page=50')
  } else {
    return (this.url = GroupCollection.__super__.url.apply(this, arguments))
  }
}

GroupCollection.prototype.fetchAll = function () {
  return this.fetchAllDriver({
    success: this.fetchNext,
  })
}

GroupCollection.prototype.fetchNext = function () {
  if (this.canFetch('next')) {
    return this.fetch({
      page: 'next',
      success: this.fetchNext,
    })
  } else {
    return this.trigger('finish')
  }
}

GroupCollection.prototype.fetchAllDriver = function (options) {
  if (options == null) {
    options = {}
  }
  // eslint-disable-next-line prefer-object-spread
  options.data = Object.assign(
    {
      per_page: 20,
      include: 'can_message',
    },
    options.data || {}
  )
  return this.fetch(options)
}

export default GroupCollection
