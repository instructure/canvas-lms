/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import Entry from '../models/Entry'
import walk from '../../array-walk'

extend(EntryCollection, Backbone.Collection)

function EntryCollection() {
  return EntryCollection.__super__.constructor.apply(this, arguments)
}

EntryCollection.prototype.defaults = {
  perPage: 50,
  initialPage: 0,
}

EntryCollection.prototype.model = Entry

EntryCollection.prototype.totalPages = function () {
  return Math.ceil(this.length / this.options.perPage)
}

EntryCollection.prototype.getPage = function (page) {
  if (page === 'next') {
    return this.getPage(this.currentPage + 1)
  }
  this.currentPage = page
  const indices = this.getPageIndicies(page)
  return this.toArray().slice(indices.start, indices.end)
}

EntryCollection.prototype.getPageIndicies = function (page) {
  const start = page * this.options.perPage
  const end = start + this.options.perPage
  return {
    start,
    end,
  }
}

EntryCollection.prototype.getPageAsCollection = function (page, options) {
  if (options == null) {
    options = this.options
  }
  page = new this.constructor(this.getPage(page), options)
  page.fullCollection = this
  return page
}

EntryCollection.prototype.setAllReadState = function (newReadState) {
  return this.each(function (entry) {
    return entry.set('read_state', newReadState)
  })
}

// This could have been two or three well-named methods, but it doesn't make
// a whole lot of sense to walk the tree over and over to get each piece of
// data that we're interested in.
//
// This takes an entry `id` and finds the entry and returns an object with
// the entry, rootParent, page, and number of levels down
EntryCollection.prototype.getEntryData = function (id) {
  let end, entry, i, levels, page, ref, ref1, rootParent, start
  entry = null
  rootParent = null
  levels = 0
  walk(
    this.toJSON(),
    'replies',
    (function (_this) {
      return function (item) {
        const isARootEntry = _this.get(item.id) != null
        if (entry === null && isARootEntry) {
          rootParent = item
        }
        if (isARootEntry) {
          levels = 0
        } else if (entry === null) {
          levels += 1
        }
        if (item.id + '' === id) {
          return (entry = item)
        }
      }
    })(this)
  )
  if (!(rootParent != null && entry != null)) {
    return null
  }
  const rootParentIndex = this.indexOf(this.get(rootParent.id))
  for (
    page = i = 0, ref = this.totalPages();
    ref >= 0 ? i <= ref : i >= ref;
    page = ref >= 0 ? ++i : --i
  ) {
    ref1 = this.getPageIndicies(page)
    start = ref1.start
    end = ref1.end
    if (rootParentIndex >= start && rootParentIndex < end) {
      break
    }
  }
  return {
    entry,
    rootParent,
    page,
    levels,
  }
}

export default EntryCollection
