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

import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import CourseEvent from '../models/CourseEvent'

class CourseLoggingCollection extends PaginatedCollection {
  url() {
    return `/api/v1/audit/course/courses/${this.options.params.id}`
  }
}

CourseLoggingCollection.prototype.model = CourseEvent

CourseLoggingCollection.prototype.sideLoad = {
  course: true,
  user: true,
  copied_to: {
    collection: 'courses',
  },
  copied_from: {
    collection: 'courses',
  },
  reset_to: {
    collection: 'courses',
  },
  reset_from: {
    collection: 'courses',
  },
}

export default CourseLoggingCollection
