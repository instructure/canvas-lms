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
import {map, difference} from 'lodash'
import AssignmentOverride from '../models/AssignmentOverride'
import Section from '@canvas/sections/backbone/models/Section'

extend(AssignmentOverrideCollection, Backbone.Collection)

// Class Summary
//   Assignments can have overrides ie DueDates.
function AssignmentOverrideCollection() {
  this.isSimple = this.isSimple.bind(this)
  this.datesJSON = this.datesJSON.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.blank = this.blank.bind(this)
  this.containsDefaultDueDate = this.containsDefaultDueDate.bind(this)
  this.getDefaultDueDate = this.getDefaultDueDate.bind(this)
  this.courseSectionIDs = this.courseSectionIDs.bind(this)
  return AssignmentOverrideCollection.__super__.constructor.apply(this, arguments)
}

AssignmentOverrideCollection.prototype.model = AssignmentOverride

AssignmentOverrideCollection.prototype.courseSectionIDs = function () {
  return this.pluck('course_section_id')
}

AssignmentOverrideCollection.prototype.comparator = function (override) {
  return override.id
}

AssignmentOverrideCollection.prototype.getDefaultDueDate = function () {
  return this.detect(function (override) {
    return override.getCourseSectionID() === Section.defaultDueDateSectionID
  })
}

AssignmentOverrideCollection.prototype.containsDefaultDueDate = function () {
  return !!this.getDefaultDueDate()
}

AssignmentOverrideCollection.prototype.blank = function () {
  return this.select(function (override) {
    return override.isBlank()
  })
}

AssignmentOverrideCollection.prototype.toJSON = function () {
  const json = this.reject(function (override) {
    return override.representsDefaultDueDate()
  })
  return map(json, function (override) {
    return override.toJSON().assignment_override
  })
}

AssignmentOverrideCollection.prototype.datesJSON = function () {
  return this.map(function (override) {
    return override.toJSON().assignment_override
  })
}

AssignmentOverrideCollection.prototype.isSimple = function () {
  return difference(this.courseSectionIDs(), [Section.defaultDueDateSectionID]).length === 0
}

export default AssignmentOverrideCollection
