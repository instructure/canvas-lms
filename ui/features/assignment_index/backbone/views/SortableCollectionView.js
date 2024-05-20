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
import {extend as lodashExtend} from 'lodash'
import $ from 'jquery'
import CollectionView from '@canvas/backbone-collection-view'
import 'jqueryui/sortable'

extend(SortableCollectionView, CollectionView)

function SortableCollectionView() {
  this._updateSort = this._updateSort.bind(this)
  return SortableCollectionView.__super__.constructor.apply(this, arguments)
}

SortableCollectionView.optionProperty('sortURL')

// Public: Default jQuery sortable options
SortableCollectionView.prototype.sortOptions = {
  tolerance: 'pointer',
  opacity: 0.9,
  zIndex: 100,
  placeholder: 'sortable-dropzone',
  forcePlaceholderSize: true,
}

SortableCollectionView.prototype.render = function (sort) {
  if (sort == null) {
    sort = true
  }
  SortableCollectionView.__super__.render.apply(this, arguments)
  if (sort) {
    this._initSort()
  }
  return this
}

// Internal: Enable sorting of the this view's itemViews.
// Returns nothing.
SortableCollectionView.prototype._initSort = function (opts) {
  if (opts == null) {
    opts = {}
  }
  this.$list.sortable(
    lodashExtend({}, this.sortOptions, opts, {
      scope: this.cid,
    })
  )
  this.$list.on('sortupdate', this._updateSort)
  return this.$list.disableSelection()
}

// Internal: get an item's ID from the ui element
// Assumes that the first child DOM element will have the id in the data-item-id attribute
SortableCollectionView.prototype._getItemId = function (item) {
  return item.children(':first').data('id')
}

// Internal: On a user's sort action, update the sort order on the server.
//
// Assumes that the first child DOM element will have the id of the model in the data-id attribute
//
// e - Event object.
// ui - jQueryUI object.
//
// Returns nothing.
SortableCollectionView.prototype._updateSort = function (e, ui) {
  e.stopPropagation()
  const positions = {}
  const id = this._getItemId(ui.item)
  positions[id] = ui.item.index() + 1
  const ref = ui.item.siblings()
  for (let i = 0, len = ref.length; i < len; i++) {
    const s = ref[i]
    const $s = $(s)
    const model_id = this._getItemId($s)
    const index = $s.prevAll().length
    positions[model_id] = index + 1
  }
  return this._updatePositions(positions)
}

// Internal: Update the position attributes of all models in the collection
// to match their DOM position. Mirror changes to server.
// Returns nothing
SortableCollectionView.prototype._updatePositions = function (positions) {
  this.collection.each(function (model, _index) {
    const new_position = positions[model.id]
    return model.set('position', new_position)
  })
  // make sure the collection stays in order
  this.collection.sort()
  return this._sendPositions(this._orderPositions(positions))
}

// Internal: takes an object of {model_id:position} and returns and array
// of model_ids in the correct order
SortableCollectionView.prototype._orderPositions = function (positions) {
  const sortable = []
  for (const id in positions) {
    const order = positions[id]
    sortable.push([id, order])
  }
  sortable.sort(function (a, b) {
    return a[1] - b[1]
  })
  const output = []
  for (let i = 0, len = sortable.length; i < len; i++) {
    const model = sortable[i]
    output.push(model[0])
  }
  return output
}

// Internal: sends an array of model_ids as a comma delimited string
// to the sortURL
SortableCollectionView.prototype._sendPositions = function (ids) {
  return $.post(this.sortURL, {
    order: ids.join(','),
  })
}

export default SortableCollectionView
