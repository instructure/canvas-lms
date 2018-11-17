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

import PaginatedCollection from '../collections/PaginatedCollection'

export default class CourseCollection extends PaginatedCollection {
  initialize() {
    super.initialize()
    this.setParam('state', ['unpublished', 'available', 'completed'])
    return this.setParam('include', ['term'])
  }
}
CourseCollection.prototype.url = '/api/v1/courses/'
CourseCollection.prototype.loadAll = true
