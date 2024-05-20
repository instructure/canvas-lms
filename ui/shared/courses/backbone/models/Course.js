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
import {omit} from 'lodash'
import {Model} from '@canvas/backbone'

extend(Course, Model)

function Course() {
  return Course.__super__.constructor.apply(this, arguments)
}

Course.prototype.modelType = 'course'

Course.prototype.resourceName = 'courses'

Course.prototype.toJSON = function () {
  return {
    course: omit(this.attributes, 'id', 'calendar', 'enrollments', 'workflow_state'),
  }
}

export default Course
