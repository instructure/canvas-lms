//
// Copyright (C) 2018 - present Instructure, Inc.
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

export default class SyllabusCalendarEventsCollection extends PaginatedCollection {
  constructor(context_codes) {
    super()
    this.url = '/api/v1/planner/items'
    this.context_codes = context_codes
  }

  fetch(options) {
    const mergedData = {
      ...options.data,
      context_codes: this.context_codes,
      filter: 'all_ungraded_todo_items',
    }
    const mergedOptions = {...options, data: mergedData}
    return super.fetch(mergedOptions)
  }

  // Overridden to make the id unique when aggregated in a collection with other
  // models and to match the fields used by the SyllabusView and template.
  parse(apiNote) {
    return apiNote.map(note => ({
      id: `planner_${note.plannable_type}_${note.plannable_id}`,
      type: note.plannable_type,
      title: note.plannable.title,
      todo_at: note.plannable.todo_date,
      start_at: note.plannable.todo_date,
      html_url: note.html_url,
    }))
  }
}
