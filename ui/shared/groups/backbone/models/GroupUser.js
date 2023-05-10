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
import $ from 'jquery'
import User from '@canvas/users/backbone/models/User'
import '@canvas/jquery/jquery.ajaxJSON'

extend(GroupUser, User)

function GroupUser() {
  this.moved = this.moved.bind(this)
  this.sync = this.sync.bind(this)
  return GroupUser.__super__.constructor.apply(this, arguments)
}

// janky sync override cuz we don't have the luxury of (ember data || backbone-relational)
GroupUser.prototype.sync = function (_method, _model, _options) {
  const group = this.get('group')
  const previousGroup = this.previous('group')
  if (group === previousGroup) {
    return
  }
  // if the user is joining another group
  if (group != null) {
    this.joinGroup(group)
  }
  // if the user is being removed from a group, or is being moved to
  // another group AND the category allows multiple memberships (in
  // which case rails won't delete the old membership, so we have to)
  if (previousGroup && (group == null || this.get('category').get('allows_multiple_memberships'))) {
    return this.leaveGroup(previousGroup)
  }
}

// creating membership will delete pre-existing membership in same group category
GroupUser.prototype.joinGroup = function (group) {
  return $.ajaxJSON(
    '/api/v1/groups/' + group.id + '/memberships',
    'POST',
    {
      user_id: this.get('id'),
    },
    (function (_this) {
      return function (data) {
        return _this.trigger('ajaxJoinGroupSuccess', data)
      }
    })(this)
  )
}

GroupUser.prototype.leaveGroup = function (group) {
  return $.ajaxJSON('/api/v1/groups/' + group.id + '/users/' + this.get('id'), 'DELETE')
}

// e.g. so the view can give the user an indication of what happened
// once everything is done
GroupUser.prototype.moved = function () {
  return this.trigger('moved', this)
}

export default GroupUser
