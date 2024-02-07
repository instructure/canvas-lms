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
import $ from 'jquery'
import {each, isEmpty, extend as lodashExtend} from 'lodash'
import CollectionView from '@canvas/backbone-collection-view'
import 'jqueryui/sortable'
import '@canvas/jquery/jquery.simulate'

extend(DraggableCollectionView, CollectionView)

function DraggableCollectionView() {
  this.updateModels = this.updateModels.bind(this)
  this._updateSort = this._updateSort.bind(this)
  this._onReceive = this._onReceive.bind(this)
  this._noItemsViewIfEmpty = this._noItemsViewIfEmpty.bind(this)
  this.modifyPlaceholder = this.modifyPlaceholder.bind(this)
  return DraggableCollectionView.__super__.constructor.apply(this, arguments)
}

DraggableCollectionView.optionProperty('parentCollection')

DraggableCollectionView.optionProperty('childKey')

DraggableCollectionView.optionProperty('groupId')

DraggableCollectionView.optionProperty('groupKey')

DraggableCollectionView.optionProperty('reorderURL')

DraggableCollectionView.optionProperty('noItemTemplate')

// A Backbone Collection of Models that have an array of items (a child collection)
// @optionProperty 'parentCollection'
// The key used to find the child collection
// @optionProperty 'childKey'
// The group's ID
// @optionProperty 'groupId'
// The group's name within the child
// @optionProperty 'groupKey'
// the URL to send reorder updates to
// @optionProperty 'reorderURL'
// the template used to fill empty groups
// @optionProperty 'noItemTemplate'
DraggableCollectionView.prototype.sortOptions = {
  tolerance: 'pointer',
  opacity: 0.9,
  zIndex: 100,
  connectWith: '.draggable.collectionViewItems',
  placeholder: 'draggable-dropzone',
  forcePlaceholderSize: true,
}

DraggableCollectionView.prototype.render = function (drag) {
  if (drag == null) {
    drag = true
  }
  DraggableCollectionView.__super__.render.apply(this, arguments)
  if (drag) {
    this.initSort()
  }
  return this
}

DraggableCollectionView.prototype.attachCollection = function () {
  DraggableCollectionView.__super__.attachCollection.apply(this, arguments)
  return this.collection.on('add', this._noItemsViewIfEmpty)
}

DraggableCollectionView.prototype.initSort = function (opts) {
  if (opts == null) {
    opts = {}
  }
  this.$list
    .sortable(
      lodashExtend({}, this.sortOptions, opts, {
        scope: this.cid,
      })
    )
    .on('sortstart', this.modifyPlaceholder)
    .on('sortreceive', this._onReceive)
    .on('sortupdate', this._updateSort)
    .on('sortremove', this._noItemsViewIfEmpty)
  this.$list.disableSelection()
  return this._noItemsViewIfEmpty()
}

DraggableCollectionView.prototype.modifyPlaceholder = function (e, ui) {
  e.stopPropagation()
  return $(ui.placeholder).data('group', this.groupId)
}

// If there are no children within the group,
// add the view that is used when there are no items in a group
DraggableCollectionView.prototype._noItemsViewIfEmpty = function () {
  const list = this.$list.children()
  if (list.length === 0) {
    return this.insertNoItemView()
  } else {
    return this.removeNoItemView()
  }
}

DraggableCollectionView.prototype.insertNoItemView = function () {
  this.noItems = new Backbone.View({
    template: this.noItemTemplate,
    tagName: 'li',
    className: 'no-items',
  })
  return this.$list.append(this.noItems.render().el)
}

DraggableCollectionView.prototype.removeNoItemView = function () {
  if (this.noItems) {
    return this.noItems.remove()
  }
}

// Find an item without knowing the group it is in
DraggableCollectionView.prototype.searchItem = function (itemId) {
  let chosen = null
  this.parentCollection.find(
    (function (_this) {
      return function (group) {
        const assignments = group.get(_this.childKey)
        const result = assignments.findWhere({
          id: itemId,
        })
        if (result != null) {
          return (chosen = result)
        }
        return undefined
      }
    })(this)
  )
  return chosen
}

// Internal: get an item's ID from the ui element
// Assumes that the first child DOM element will have the id in the data-item-id attribute
DraggableCollectionView.prototype._getItemId = function (item) {
  const id = item.children(':first').data('item-id')
  return id && String(id)
}

// Internal: When an item is moved from one group to another
// Assumes that the first child DOM element will have the id of the model in the data-item-id attribute
//
// e - Event object
// ui - jQueryUI object
//
// Returns nothing.
DraggableCollectionView.prototype._onReceive = function (e, ui) {
  const item_id = this._getItemId(ui.item)
  const model = this.searchItem(item_id)
  this._removeFromGroup(model)
  return this._addToGroup(model)
}

// must explicitly update @empty attribute from CollectionView class so view
// will properly recognize if it does/doesn't have items on subsequent
// re-renders, since drag & drop doesn't trigger a render
DraggableCollectionView.prototype._removeFromGroup = function (model) {
  const old_group_id = model.get(this.groupKey)
  const old_group = this.parentCollection.findWhere({
    id: old_group_id,
  })
  const old_children = old_group.get(this.childKey)
  old_children.remove(model, {
    silent: true,
  })
  return (this.empty = isEmpty(old_children.models))
}

DraggableCollectionView.prototype._addToGroup = function (model) {
  model.set(this.groupKey, this.groupId)
  const new_group = this.parentCollection.findWhere({
    id: this.groupId,
  })
  const new_children = new_group.get(this.childKey)
  new_children.add(model, {
    silent: true,
  })
  if (this.empty) {
    return (this.empty = false)
  }
}

// Internal: On a user's sort action, update the sort order on the server.
//
// Assumes that the first child DOM element will have the id of the model in the data-item-id attribute
//
// e - Event object.
// ui - jQueryUI object.
//
// Returns nothing.
DraggableCollectionView.prototype._updateSort = function (e, ui) {
  e.stopImmediatePropagation()
  // if the ui.item is not still inside the view, we only want to
  // resort, not save
  const shouldSave = this.$(ui.item).length
  const id = this._getItemId(ui.item)
  const model = this.collection.get(id)
  const new_index = ui.item.index()
  this.updateModels(model, new_index, shouldSave)
  if (shouldSave) {
    model.set('position', new_index + 1)
    // will still have the moved model in the collection for now
    this.collection.sort()
    return this._sendPositions(this.collection.pluck('id'))
  } else {
    return this.collection.sort()
  }
}

DraggableCollectionView.prototype.updateModels = function (model, new_index, inView) {
  let old_index
  // start at the model's current position because we don't want to include the model in the slice,
  // we'll update it separately
  const old_pos = model.get('position')
  if (old_pos) {
    old_index = old_pos - 1
  }
  const movedDown = old_index < new_index
  // figure out how to slice the models
  const slice_args = !inView
    ? // model is being removed so we need to update everything
      // after it
      (model.unset('position'), [old_index])
    : !old_pos
    ? // model is new so we need to update everything after it
      [new_index]
    : movedDown
    ? // model is new so we need to update everything after it
      // we want to include the one at new index
      // so we add 1
      [old_index, new_index + 1]
    : // moved up so slice from new to old
      [new_index, old_index + 1]
  // carve out just the models that need updating
  // eslint-disable-next-line prefer-spread
  const models_to_update = this.collection.slice.apply(this.collection, slice_args)
  // update the position on just these models
  each(models_to_update, function (m) {
    // if the model gets sliced in here, don't update its
    // position as we'll update it later
    if (m.id !== model.id) {
      const old = m.get('position')
      // if we moved an item down we want to move
      // the shifted items up (so we subtract 1)
      const neue = !inView || movedDown ? old - 1 : old + 1
      return m.set('position', neue)
    }
  })
}

// Internal: sends an array of model_ids as a comma delimited string
// to the sortURL
DraggableCollectionView.prototype._sendPositions = function (ids) {
  return $.post(this.reorderURL, {
    order: ids.join(','),
  })
}

export default DraggableCollectionView
