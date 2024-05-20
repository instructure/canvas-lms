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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import GroupUser from '../models/GroupUser'
import h from '@instructure/html-escape'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('GroupUserCollection')

extend(GroupUserCollection, PaginatedCollection)

function GroupUserCollection() {
  this.onChangeGroup = this.onChangeGroup.bind(this)
  return GroupUserCollection.__super__.constructor.apply(this, arguments)
}

GroupUserCollection.prototype.comparator = function (user) {
  return user.get('sortable_name').toLowerCase()
}

GroupUserCollection.optionProperty('group')

GroupUserCollection.optionProperty('category')

GroupUserCollection.optionProperty('markInactiveStudents')

GroupUserCollection.prototype.url = function () {
  const url_base = '/api/v1/groups/' + this.group.id + '/users?'
  const params = {
    per_page: 50,
    include: ['sections', 'group_submissions'],
    exclude: ['pseudonym'],
  }
  if (this.markInactiveStudents) {
    params.include.push('active_status')
  }
  return url_base + encodeQueryString(params)
}

GroupUserCollection.prototype.initialize = function (models) {
  GroupUserCollection.__super__.initialize.apply(this, arguments)
  this.loaded = this.loadedAll = models != null
  this.on('change:group', this.onChangeGroup)
  return (this.model = GroupUser.extend({
    defaults: {
      group: this.group,
      category: this.category,
    },
  }))
}

GroupUserCollection.prototype.load = function (target) {
  if (target == null) {
    target = 'all'
  }
  this.loadAll = target === 'all'
  this.loaded = true
  if (target !== 'none') {
    this.fetch()
  }
  return (this.load = function () {})
}

GroupUserCollection.prototype.onChangeGroup = function (model, group) {
  let ref
  this.removeUser(model)
  return (ref = this.groupUsersFor(group)) != null ? ref.addUser(model) : void 0
}

GroupUserCollection.prototype.membershipsLocked = function () {
  return false
}

GroupUserCollection.prototype.getUser = function (asset_string) {
  return this.get(asset_string.replace('user_', ''))
}

GroupUserCollection.prototype.addUser = function (user) {
  let ref
  if (this.membershipsLocked()) {
    if ((ref = this.get(user)) != null) {
      ref.moved()
    }
    return
  }
  if (this.loaded) {
    if (this.get(user)) {
      this.flashAlreadyInGroupError(user)
    } else {
      this.add(user)
      this.increment(1)
    }
    return user.moved()
  } else {
    user.once(
      'ajaxJoinGroupSuccess',
      (function (_this) {
        return function (data) {
          if (data.just_created) {
            return
          }
          // uh oh, we already had this user -- undo the increment and flash an error.
          _this.increment(-1)
          return _this.flashAlreadyInGroupError(user)
        }
      })(this)
    )
    return this.increment(1)
  }
}

GroupUserCollection.prototype.flashAlreadyInGroupError = function (user) {
  return $.flashError(
    I18n.t('flash.userAlreadyInGroup', 'WARNING: %{user} is already a member of %{group}', {
      user: h(user.get('name')),
      group: h(this.group.get('name')),
    })
  )
}

GroupUserCollection.prototype.removeUser = function (user) {
  let ref, ref1
  if (this.membershipsLocked()) {
    return
  }
  this.increment(-1)
  if (
    ((ref = this.group) != null
      ? (ref1 = ref.get('leader')) != null
        ? ref1.id
        : void 0
      : void 0) === user.id
  ) {
    this.group.set('leader', null)
  }
  if (this.loaded) {
    return this.remove(user)
  }
}

GroupUserCollection.prototype.increment = function (amount) {
  return this.group.increment('members_count', amount)
}

GroupUserCollection.prototype.groupUsersFor = function (group) {
  let ref
  return (ref = this.category) != null ? ref.groupUsersFor(group) : void 0
}

export default GroupUserCollection
