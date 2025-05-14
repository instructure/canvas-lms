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

import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import RosterUser from '../models/RosterUser'

export default class RosterUserCollection extends PaginatedCollection {
  constructor(models, options = {}) {
    super(models, options)
    // Keep track of selected user IDs in this collection
    this.selectedUserIds = []
    // Flag to remember if the 'master checkbox' is fully checked
    this.masterSelected = false

    // Keep track of *manually* de-selected users when masterSelected is true
    this.deselectedUserIds = []

    // Keep track of the last checked index for the checkbox
    this.lastCheckedIndex = null
  }

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
