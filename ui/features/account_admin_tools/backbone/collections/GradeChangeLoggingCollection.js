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

import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection.coffee'

export default class GradeChangeLoggingCollection extends PaginatedCollection {
  url() {
    // TODO remove this check after OSS instances have been given a path to migrate from cassandra auditors
    if (ENV.enhanced_grade_change_query) {
      return '/api/v1/audit/grade_change'
    } else {
      return `/api/v1/audit/grade_change/${this.options.params.type}/${this.options.params.id}`
    }
  }
}
GradeChangeLoggingCollection.prototype.sideLoad = {
  grader: {
    foreignKey: 'grader',
    collection: 'users'
  },
  student: {
    foreignKey: 'student',
    collection: 'users'
  },
  course: {
    foreignKey: 'course',
    collection: 'courses'
  },
  assignment: {
    foreignKey: 'assignment',
    collection: 'assignments'
  }
}
