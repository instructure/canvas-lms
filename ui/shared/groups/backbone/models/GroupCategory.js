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
import {omit} from 'lodash'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import GroupCollection from '../collections/GroupCollection'
import UnassignedGroupUserCollection from '../collections/UnassignedGroupUserCollection'
import progressable from '@canvas/progress/backbone/models/progressable'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'

extend(GroupCategory, Backbone.Model)

function GroupCategory() {
  this.setUpProgress = this.setUpProgress.bind(this)
  this.groupRemoved = this.groupRemoved.bind(this)
  return GroupCategory.__super__.constructor.apply(this, arguments)
}

GroupCategory.prototype.resourceName = 'group_categories'

GroupCategory.mixin(progressable)

GroupCategory.prototype.initialize = function () {
  let groups
  GroupCategory.__super__.initialize.apply(this, arguments)
  if ((groups = this.get('groups'))) {
    this.groups(groups)
  }
  return this.on('change:group_limit', this.updateGroups)
}

GroupCategory.prototype.updateGroups = function () {
  if (this._groups) {
    return this._groups.fetch()
  }
}

GroupCategory.prototype.groups = function (models) {
  let ref, ref1
  if (models == null) {
    models = null
  }
  this._groups = new GroupCollection(models, {
    category: this,
    loadAll: true,
    markInactiveStudents:
      (ref = this.collection) != null
        ? (ref1 = ref.options) != null
          ? ref1.markInactiveStudents
          : void 0
        : void 0,
  })
  if (this.get('groups_count') === 0 || (models != null ? models.length : void 0)) {
    this._groups.loadedAll = true
  } else {
    this._groups.fetch()
  }
  this._groups.on(
    'fetched:last',
    (function (_this) {
      return function () {
        return _this.set('groups_count', _this._groups.length)
      }
    })(this)
  )
  this._groups.on('remove', this.groupRemoved)
  this.groups = function () {
    return this._groups
  }
  return this._groups
}

GroupCategory.prototype.groupRemoved = function (group) {
  // update/reset the unassigned users collection (if it's around)
  let i, len, models, user
  if (!(this._unassignedUsers || group.usersCount())) {
    return
  }
  const users = group.users()
  if (users.loadedAll) {
    models = users.models.slice()
    for (i = 0, len = models.length; i < len; i++) {
      user = models[i]
      user.set('group', null)
    }
    // if user is in _unassignedUsers and we allow multiple memberships,
    // don't actually move the user, move a copy instead
  } else if (!this.get('allows_multiple_memberships')) {
    this._unassignedUsers.increment(group.usersCount())
  }
  if (
    !this.get('allows_multiple_memberships') &&
    (!users.loadedAll || !this._unassignedUsers.loadedAll)
  ) {
    return this._unassignedUsers.fetch()
  }
}

GroupCategory.prototype.reassignUser = function (user, newGroup) {
  const oldGroup = user.get('group')
  if (oldGroup === newGroup) {
    return
  }
  if (oldGroup == null && this.get('allows_multiple_memberships')) {
    user = user.clone()
    user.once(
      'change:group',
      (function (_this) {
        return function () {
          return _this.groupUsersFor(newGroup).addUser(user)
        }
      })(this)
    )
  }
  return user.save({
    group: newGroup,
  })
}

GroupCategory.prototype.groupsCount = function () {
  let ref
  if ((ref = this._groups) != null ? ref.loadedAll : void 0) {
    return this._groups.length
  } else {
    return this.get('groups_count')
  }
}

GroupCategory.prototype.groupUsersFor = function (group) {
  if (group != null) {
    return group._users
  } else {
    return this._unassignedUsers
  }
}

GroupCategory.prototype.unassignedUsers = function () {
  this._unassignedUsers = new UnassignedGroupUserCollection(null, {
    category: this,
  })
  this._unassignedUsers.on(
    'fetched:last',
    (function (_this) {
      return function () {
        return _this.set('unassigned_users_count', _this._unassignedUsers.length)
      }
    })(this)
  )
  this.unassignedUsers = function () {
    return this._unassignedUsers
  }
  return this._unassignedUsers
}

GroupCategory.prototype.unassignedUsersCount = function () {
  return this.get('unassigned_users_count')
}

GroupCategory.prototype.canAssignUnassignedMembers = function () {
  return (
    this.groupsCount() > 0 &&
    !this.get('allows_multiple_memberships') &&
    this.get('self_signup') !== 'restricted' &&
    this.unassignedUsersCount() > 0
  )
}

GroupCategory.prototype.canMessageUnassignedMembers = function () {
  return this.unassignedUsersCount() > 0 && !ENV.IS_LARGE_ROSTER
}

GroupCategory.prototype.isLocked = function () {
  // e.g. SIS groups, we shouldn't be able to edit them
  return this.get('role') === 'uncategorized'
}

GroupCategory.prototype.assignUnassignedMembers = function (group_by_section) {
  let qs
  if (group_by_section) {
    qs = '?group_by_section=1'
  } else {
    qs = ''
  }
  return $.ajaxJSON(
    '/api/v1/group_categories/' + this.id + '/assign_unassigned_members' + qs,
    'POST',
    {},
    this.setUpProgress
  )
}

GroupCategory.prototype.cloneGroupCategoryWithName = function (name) {
  return $.ajaxJSON('/group_categories/' + this.id + '/clone_with_name', 'POST', {
    name,
  })
}

GroupCategory.prototype.setUpProgress = function (response) {
  return this.set({
    progress_url: response.url,
  })
}

GroupCategory.prototype.present = function () {
  const data = Backbone.Model.prototype.toJSON.call(this)
  data.progress = this.progressModel.toJSON()
  data.groupCreationInProgress =
    data.progress.workflow_state === 'queued' || data.progress.workflow_state === 'running'
  return data
}

GroupCategory.prototype.toJSON = function () {
  return omit(GroupCategory.__super__.toJSON.apply(this, arguments), 'self_signup')
}

GroupCategory.mixin(DefaultUrlMixin)

GroupCategory.prototype.sync = function (method, model, options) {
  let group_by_section, ref, success
  if (options == null) {
    options = {}
  }
  options.url = this.urlFor(method)
  if (
    method === 'create' &&
    (model.get('split_groups') === '1' || model.get('split_groups') === '2')
  ) {
    model.set('assign_async', true) // if we don't specify this, it will auto-assign on creation, not asyncronously
    group_by_section = model.get('group_by_section') === '1'
    success = (ref = options.success) != null ? ref : function () {}
    options.success = (function (_this) {
      return function (args) {
        _this.progressStarting = true
        success(args)
        return _this.assignUnassignedMembers(group_by_section)
      }
    })(this)
  } else if (method === 'delete') {
    if (model.progressModel) {
      model.progressModel.onPoll = function () {}
    }
  }
  return Backbone.sync(method, model, options)
}

GroupCategory.prototype.urlFor = function (method) {
  if (method === 'create') {
    return this._defaultUrl()
  } else {
    return (
      '/api/v1/group_categories/' +
      this.id +
      '?includes[]=unassigned_users_count&includes[]=groups_count'
    )
  }
}

export default GroupCategory
