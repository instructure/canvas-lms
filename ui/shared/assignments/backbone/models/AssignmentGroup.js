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
import Backbone from '@canvas/backbone'
import {intersection, isEmpty} from 'lodash'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import AssignmentCollection from '../collections/AssignmentCollection'

const isAdmin = function () {
  return ENV.current_user_is_admin
}

extend(AssignmentGroup, Backbone.Model)

function AssignmentGroup() {
  return AssignmentGroup.__super__.constructor.apply(this, arguments)
}

AssignmentGroup.mixin(DefaultUrlMixin)

AssignmentGroup.prototype.resourceName = 'assignment_groups'

AssignmentGroup.prototype.urlRoot = function () {
  return this._defaultUrl()
}

AssignmentGroup.prototype.initialize = function () {
  let assignments
  if ((assignments = this.get('assignments')) != null) {
    return this.set('assignments', new AssignmentCollection(assignments))
  }
}

AssignmentGroup.prototype.name = function (newName) {
  if (!(arguments.length > 0)) {
    return this.get('name')
  }
  return this.set('name', newName)
}

AssignmentGroup.prototype.position = function (newPosition) {
  if (!(arguments.length > 0)) {
    return this.get('position') || 0
  }
  return this.set('position', newPosition)
}

AssignmentGroup.prototype.groupWeight = function (newWeight) {
  if (!(arguments.length > 0)) {
    return this.get('group_weight') || 0
  }
  return this.set('group_weight', newWeight)
}

AssignmentGroup.prototype.rules = function (newRules) {
  if (!(arguments.length > 0)) {
    return this.get('rules')
  }
  return this.set('rules', newRules)
}

AssignmentGroup.prototype.removeNeverDrops = function () {
  const rules = this.rules()
  if (rules.never_drop) {
    return delete rules.never_drop
  }
}

AssignmentGroup.prototype.hasRules = function () {
  return this.countRules() > 0
}

AssignmentGroup.prototype.countRules = function () {
  const rules = this.rules() || {}
  const aids = this.assignmentIds()
  let count = 0
  for (const k in rules) {
    const v = rules[k]
    if (k === 'never_drop') {
      count += intersection(aids, v).length
    } else {
      count++
    }
  }
  return count
}

AssignmentGroup.prototype.assignmentIds = function () {
  const assignments = this.get('assignments')
  if (assignments == null) {
    return []
  }
  return assignments.pluck('id')
}

AssignmentGroup.prototype.canDelete = function () {
  if (isAdmin()) {
    return true
  }
  return !this.anyAssignmentInClosedGradingPeriod() && !this.hasFrozenAssignments()
}

AssignmentGroup.prototype.hasFrozenAssignments = function () {
  return this.get('assignments').any(function (m) {
    return m.get('frozen')
  })
}

AssignmentGroup.prototype.anyAssignmentInClosedGradingPeriod = function () {
  return this.get('any_assignment_in_closed_grading_period')
}

AssignmentGroup.prototype.hasIntegrationData = function () {
  return !isEmpty(this.get('integration_data')) || !isEmpty(this.get('sis_source_id'))
}

export default AssignmentGroup
