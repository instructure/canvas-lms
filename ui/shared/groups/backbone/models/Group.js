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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import GroupUserCollection from '../collections/GroupUserCollection'

extend(Group, Backbone.Model)

function Group() {
  return Group.__super__.constructor.apply(this, arguments)
}

Group.prototype.modelType = 'group'

Group.prototype.resourceName = 'groups'

Group.prototype.initialize = function (attrs, options) {
  Group.__super__.initialize.apply(this, arguments)
  return (this.newAndEmpty = options != null ? options.newAndEmpty : void 0)
}

Group.prototype.users = function () {
  let ref, ref1, ref2
  const initialUsers = this.newAndEmpty ? [] : null
  this._users = new GroupUserCollection(initialUsers, {
    group: this,
    category: (ref = this.collection) != null ? ref.category : void 0,
    markInactiveStudents:
      (ref1 = this.collection) != null
        ? (ref2 = ref1.options) != null
          ? ref2.markInactiveStudents
          : void 0
        : void 0,
  })
  this._users.on(
    'fetched:last',
    (function (_this) {
      return function () {
        return _this.set('members_count', _this._users.length)
      }
    })(this)
  )
  this.users = function () {
    return this._users
  }
  return this._users
}

Group.prototype.usersCount = function () {
  return this.get('members_count')
}

Group.prototype.sync = function (method, model, options) {
  if (options == null) {
    options = {}
  }
  options.url = this.urlFor(method)
  return Backbone.sync(method, model, options)
}

Group.prototype.urlFor = function (method) {
  if (method === 'create') {
    return '/api/v1/group_categories/' + this.get('group_category_id') + '/groups'
  } else {
    return '/api/v1/groups/' + this.id
  }
}

Group.prototype.theLimit = function () {
  let ref, ref1
  const max_membership = this.get('max_membership')
  return (
    max_membership ||
    ((ref = this.collection) != null
      ? (ref1 = ref.category) != null
        ? ref1.get('group_limit')
        : void 0
      : void 0)
  )
}

Group.prototype.isFull = function () {
  const limit = this.get('max_membership')
  return (!limit && this.groupCategoryLimitMet()) || (limit && this.get('members_count') >= limit)
}

Group.prototype.groupCategoryLimitMet = function () {
  let ref, ref1
  const limit =
    (ref = this.collection) != null
      ? (ref1 = ref.category) != null
        ? ref1.get('group_limit')
        : void 0
      : void 0
  return limit && this.get('members_count') >= limit
}

Group.prototype.isLocked = function () {
  let ref, ref1
  return (ref = this.collection) != null
    ? (ref1 = ref.category) != null
      ? ref1.isLocked()
      : void 0
    : void 0
}

Group.prototype.toJSON = function () {
  if (ENV.student_mode) {
    return {
      name: this.get('name'),
    }
  } else {
    const json = Group.__super__.toJSON.apply(this, arguments)
    json.isFull = this.isFull()
    return json
  }
}

export default Group
