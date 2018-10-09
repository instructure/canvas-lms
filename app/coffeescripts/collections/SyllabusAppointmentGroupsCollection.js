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

import _ from 'underscore'

import PaginatedCollection from '../collections/PaginatedCollection'

export default class SyllabusAppointmentGroupsCollection extends PaginatedCollection {
  initialize(context_codes, scope = 'reservable') {
    this.context_codes = context_codes
    this.scope = scope
    return super.initialize(...arguments)
  }

  fetch(options = {}) {
    if (options.remove == null) options.remove = false

    if (options.data == null) options.data = {}
    options.data.scope = this.scope
    options.data.context_codes = this.context_codes
    if (options.data.include_past_appointments == null) {
      options.data.include_past_appointments = '1'
    }

    return super.fetch(options)
  }

  // Overridden to make the id unique when aggregated in
  // a collection with other models
  parse(resp) {
    _.each(super.parse(...arguments), ev => (ev.related_id = ev.id = `appointment_group_${ev.id}`))
    return resp
  }
}
SyllabusAppointmentGroupsCollection.prototype.url = '/api/v1/appointment_groups'
