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
import WikiPage from '@canvas/wiki/backbone/models/WikiPage'

export default class WikiPageCollection extends PaginatedCollection {
  initialize() {
    super.initialize(...arguments)

    this.sortOrders = {
      title: 'asc',
      created_at: 'desc',
      updated_at: 'desc',
      todo_date: 'desc',
    }
    this.setSortField('title')

    // remove the front_page indicator on all other models when one is set
    return this.on('change:front_page', (model, value) => {
      // only change other models if one of the models is being set to true
      if (!value) return

      for (const m of this.filter(m_ => !!m_.get('front_page'))) {
        if (m !== model) m.set('front_page', false)
      }
    })
  }

  sortByField(sortField, sortOrder = null) {
    this.setSortField(sortField, sortOrder)
    return this.fetch()
  }

  setSortField(sortField, sortOrder = null) {
    if (this.sortOrders[sortField] === undefined)
      throw new Error(`${sortField} is not a valid sort field`)

    // toggle the sort order if no sort order is specified and the sort field is the current sort field
    if (!sortOrder && this.currentSortField === sortField) {
      sortOrder = this.sortOrders[sortField] === 'asc' ? 'desc' : 'asc'
    }

    this.currentSortField = sortField
    if (sortOrder) this.sortOrders[this.currentSortField] = sortOrder

    this.setParams({
      sort: this.currentSortField,
      order: this.sortOrders[this.currentSortField],
    })

    return this.trigger('sortChanged', this.currentSortField, this.sortOrders)
  }
}
WikiPageCollection.prototype.model = WikiPage
