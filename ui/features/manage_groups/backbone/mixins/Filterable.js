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

/* eslint-disable object-shorthand */

import {some} from 'lodash'

// Mixin to make your (Paginated)CollectionView filterable on the client
// side. Just put an <input class="filterable> in your template, mix in
// this mixin, and you're good to go.
//
// Filterable simple hides the item views in the DOM, keeping stuff nice
// and fast (no need to fetch from the server, no need to re-render
// anything)

export default {
  els: {
    '.filterable': '$filter',
    '.no-results': '$noResults',
  },
  defaults: {
    filterColumns: ['name'],
  },
  afterRender: function () {
    let ref, ref1
    if ((ref = this.$filter) != null) {
      ref.on(
        'input',
        (function (_this) {
          return function () {
            return _this.setFilter(_this.$filter.val())
          }
        })(this)
      )
    }
    // eslint-disable-next-line no-void
    return (ref1 = this.$filter) != null ? ref1.trigger('input') : void 0
  },
  setFilter: function (filter) {
    let i, len, model
    this.filter = filter.toLowerCase()
    const ref = this.collection.models
    for (i = 0, len = ref.length; i < len; i++) {
      model = ref[i]
      model.trigger('filterOut', this.filterOut(model))
    }
    // show a "no results" message if there are items but they are all
    // filtered out
    return this.$noResults.toggleClass(
      'hidden',
      !(
        this.filter &&
        !this.collection.fetchingPage &&
        this.collection.length > 0 &&
        this.$list.children(':visible').length === 0
      )
    )
  },
  attachItemView: function (model, view) {
    const filterView = function (filtered) {
      return view.$el.toggleClass('hidden', filtered)
    }
    model.on('filterOut', filterView)
    return filterView(this.filterOut(model))
  },

  // Return whether or not the model (and its view) should be hidden
  // based on the current filter
  filterOut: function (model) {
    if (!this.filter) {
      return false
    }
    if (!this.options.filterColumns.length) {
      return false
    }
    if (
      some(
        this.options.filterColumns,
        (function (_this) {
          return function (col) {
            return model.get(col).toLowerCase().indexOf(_this.filter) >= 0
          }
        })(this)
      )
    ) {
      return false
    }
    return true
  },
}
