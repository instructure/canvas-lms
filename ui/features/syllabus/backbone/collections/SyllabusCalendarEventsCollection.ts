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

import {each} from 'es-toolkit/compat'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'
import type {SyllabusEventApi, SyllabusEventType, SyllabusFetchOptions} from '../types'

// @ts-expect-error TS7 migration
export default class SyllabusCalendarEventsCollection extends PaginatedCollection {
  declare context_codes: string[]
  declare type: SyllabusEventType
  declare url: string

  constructor(context_codes: string[], type: SyllabusEventType = 'event') {
    super()
    this.context_codes = context_codes
    this.type = type
    this.url = '/api/v1/calendar_events'
  }

  fetch(options: SyllabusFetchOptions = {}) {
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
  parse(resp: SyllabusEventApi[]) {
    const eventType = this.type
    let normalize: (ev: SyllabusEventApi) => SyllabusEventApi = ev => ev

    switch (eventType) {
      case 'assignment':
        normalize = ev => {
          ev.related_id = ev.id

          let overridden = false
          each(ev.assignment_overrides ?? [], override => {
            if (!overridden) {
              ev.id = `${ev.id}_override_${override.id}`
              overridden = true
            }
          })
          return ev
        }
        break
      case 'sub_assignment':
        normalize = ev => {
          ev.related_id = ev.id

          let overridden = false
          each(ev.sub_assignment_overrides ?? [], override => {
            if (!overridden) {
              ev.id = `${ev.id}_override_${override.id}`
              overridden = true
            }
          })
          return ev
        }
        break
      case 'event':
        normalize = ev => {
          ev.related_id = ev.id = `${eventType}_${ev.id}`
          if (ev.parent_event_id) {
            ev.related_id = `${eventType}_${ev.parent_event_id}`
          }
          return ev
        }
        break
      default:
        normalize = ev => ev
    }

    const result: SyllabusEventApi[] = []
    each(resp, ev => {
      if (!ev.hidden) result.push(normalize(ev))
    })
    return result
  }
}
