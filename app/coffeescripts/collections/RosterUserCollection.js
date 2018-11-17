//
// Copyright (C) 2013 - present Instructure, Inc.
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

import RosterUser from '../models/RosterUser'

export default class RosterUserCollection extends PaginatedCollection {
  url() {
    return `/api/v1/courses/${this.options.course_id}/users?include_inactive=true`
  }
}
RosterUserCollection.prototype.model = RosterUser

// #
// The course id the users belong to
RosterUserCollection.optionProperty('course_id')

// #
// A SectionCollection
RosterUserCollection.optionProperty('sections')
