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
//

import {each} from 'lodash'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'

export default class SyllabusCalendarEventsCollection extends PaginatedCollection {
  initialize(context_codes, type = 'event') {
    this.parse = this.parse.bind(this)
    this.context_codes = context_codes
    this.type = type
    return super.initialize(...arguments)
  }

  fetch(options = {}) {
    if (options.remove == null) options.remove = false
    if (options.data == null) options.data = {}

    options.data.type = this.type
    options.data.context_codes = this.context_codes
    if (options.data.all_events == null) {
      options.data.all_events = '1'
    }
    options.data.excludes = ['assignment', 'description', 'child_events']

    return super.fetch(options)
  }

  // Overridden to make the id unique when aggregated in
  // a collection with other models, and to exclude
  // 'hidden' events
  parse(...args) {
    let normalize
    const eventType = this.type
    switch (eventType) {
      case 'assignment':
        normalize = function (ev) {
          ev.related_id = ev.id

          let overridden = false
          each(ev.assignment_overrides != null ? ev.assignment_overrides : [], override => {
            if (!overridden) {
              ev.id = `${ev.id}_override_${override.id}`
              return (overridden = true)
            }
          })
          return ev
        }
        break

      case 'event':
        normalize = function (ev) {
          ev.related_id = ev.id = `${eventType}_${ev.id}`
          if (ev.parent_event_id) {
            ev.related_id = `${eventType}_${ev.parent_event_id}`
          }
          return ev
        }
        break
    }

    const result = []
    each(super.parse(...args), ev => {
      if (!ev.hidden) result.push(normalize(ev))
    })
    return result
  }
}
SyllabusCalendarEventsCollection.prototype.url = '/api/v1/calendar_events'
