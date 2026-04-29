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

import {some} from 'es-toolkit/compat'

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
  // @ts-expect-error - Legacy Backbone typing
  afterRender: function () {
    let ref, ref1
    // @ts-expect-error - Backbone View property
    if ((ref = this.$filter) != null) {
      ref.on(
        'input',
        (function (_this) {
          return function () {
            // @ts-expect-error - Backbone View property
            return _this.setFilter(_this.$filter.val())
          }
        })(this),
      )
    }

    // @ts-expect-error - Backbone View property
    return (ref1 = this.$filter) != null ? ref1.trigger('input') : void 0
  },
  // @ts-expect-error - Legacy Backbone typing
  setFilter: function (filter) {
    let i, len, model
    // @ts-expect-error - Backbone View property
    this.filter = filter.toLowerCase()
    // @ts-expect-error - Backbone View property
    const ref = this.collection.models
    for (i = 0, len = ref.length; i < len; i++) {
      model = ref[i]
      model.trigger('filterOut', this.filterOut(model))
    }
    // show a "no results" message if there are items but they are all
    // filtered out
    const currentFilter = (this as any).filter
    // @ts-expect-error - Backbone View property
    return this.$noResults.toggleClass(
      'hidden',
      !(
        currentFilter &&
        // @ts-expect-error - Backbone View property
        !this.collection.fetchingPage &&
        // @ts-expect-error - Backbone View property
        this.collection.length > 0 &&
        // @ts-expect-error - Backbone View property
        this.$list.children(':visible').length === 0
      ),
    )
  },
  // @ts-expect-error - Legacy Backbone typing
  attachItemView: function (model, view) {
    // @ts-expect-error - Legacy Backbone typing
    const filterView = function (filtered) {
      return view.$el.toggleClass('hidden', filtered)
    }
    model.on('filterOut', filterView)
    return filterView(this.filterOut(model))
  },

  // Return whether or not the model (and its view) should be hidden
  // based on the current filter
  // @ts-expect-error - Legacy Backbone typing
  filterOut: function (model) {
    // @ts-expect-error - Backbone View property
    if (!this.filter) {
      return false
    }
    // @ts-expect-error - Backbone View property
    if (!this.options.filterColumns.length) {
      return false
    }
    if (
      some(
        // @ts-expect-error - Backbone View property
        this.options.filterColumns,
        (function (_this) {
          return function (col) {
            // @ts-expect-error - Backbone View property
            return model.get(col).toLowerCase().indexOf(_this.filter) >= 0
          }
        })(this),
      )
    ) {
      return false
    }
    return true
  },
}
