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
import GroupUserCollection from './GroupUserCollection'

extend(UnassignedGroupUserCollection, GroupUserCollection)

function UnassignedGroupUserCollection() {
  return UnassignedGroupUserCollection.__super__.constructor.apply(this, arguments)
}

UnassignedGroupUserCollection.prototype.url = function () {
  let _url =
    '/api/v1/group_categories/' +
    this.category.id +
    '/users?per_page=50&include[]=sections&exclude[]=pseudonym'
  if (!this.category.get('allows_multiple_memberships')) {
    _url += '&unassigned=true&include[]=group_submissions'
  }
  return (this.url = _url)
}

// # don't add/remove people in the "Everyone" collection (this collection)
// # if the category supports multiple memberships
UnassignedGroupUserCollection.prototype.membershipsLocked = function () {
  return this.category.get('allows_multiple_memberships')
}

UnassignedGroupUserCollection.prototype.increment = function (amount) {
  return this.category.increment('unassigned_users_count', amount)
}

UnassignedGroupUserCollection.prototype.search = function (filter, options) {
  options = options || {}
  options.reset = true
  if (filter && filter.length >= 3) {
    options.url = this.url + '&search_term=' + filter
    this.filtered = true
    return this.fetch(options)
  } else if (this.filtered) {
    this.filtered = false
    options.url = this.url
    return this.fetch(options)
  }
}

export default UnassignedGroupUserCollection
