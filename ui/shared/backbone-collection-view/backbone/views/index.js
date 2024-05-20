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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../jst/index.handlebars'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

const I18n = useI18nScope('CollectionView')

extend(CollectionView, Backbone.View)

// Renders a collection of items with an item view. Binds to a handful of
// collection events to keep itself up-to-date
//
// Example:
//
//   peopleCollection = new PeopleCollection
//   view = new CollectionView
//     itemView: PersonView
//     collection: peopleCollection
//   peopleCollection.add name: 'ryanf', id: 1
//   peopleCollection.fetch()
//   # etc.

function CollectionView() {
  this.renderItem = this.renderItem.bind(this)
  this.renderOnAdd = this.renderOnAdd.bind(this)
  this.removeItem = this.removeItem.bind(this)
  this.renderOnReset = this.renderOnReset.bind(this)
  this.removePreviousItems = this.removePreviousItems.bind(this)
  this.reorder = this.reorder.bind(this)
  this.render = this.render.bind(this)
  return CollectionView.__super__.constructor.apply(this, arguments)
}

// The backbone view rendered for collection items
CollectionView.optionProperty('itemView')

CollectionView.optionProperty('itemViewOptions')

CollectionView.optionProperty('emptyMessage')

CollectionView.optionProperty('listClassName')

CollectionView.prototype.className = 'collectionView'

CollectionView.prototype.els = {
  '.collectionViewItems': '$list',
}

CollectionView.prototype.defaults = shimGetterShorthand(
  {
    itemViewOptions: {},
  },
  {
    emptyMessage() {
      return I18n.t('no_items', 'No items.')
    },
  }
)

// When using a different template ensure it contains an element with a
// class of `.collectionViewItems`
CollectionView.prototype.template = template

// Options:
//
//  - `itemView` {Backbone.View}
//  - `collection` {Backbone.Collection}
//
// @param {Object} options
// @api public
CollectionView.prototype.initialize = function (_options) {
  CollectionView.__super__.initialize.apply(this, arguments)
  return this.attachCollection()
}

// Renders the main template and the item templates
//
// @api public
CollectionView.prototype.render = function () {
  CollectionView.__super__.render.apply(this, arguments)
  if (!this.empty) {
    this.renderItems()
  }
  return this
}

// @api public
CollectionView.prototype.toJSON = function () {
  return {
    ...this.options,
    emptyMessage: this.emptyMessage,
    listClassName: this.listClassName,
    ENV,
  }
}

// Reorder child views according to current collection ordering.
// Useful when your collection has a comparator and that field
// changes on a given model, e.g.
//
//   @on 'change:name', @reorder
//
// @api public
CollectionView.prototype.reorder = function () {
  let model, ref
  this.collection.sort()
  this.$list.children().detach()
  const children = function () {
    let i, len
    ref = this.collection.models
    const results = []
    for (i = 0, len = ref.length; i < len; i++) {
      model = ref[i]
      results.push(model.itemView.$el)
    }
    return results
  }.call(this)
  return (ref = this.$list).append.apply(ref, children)
}

// Attaches all the collection events
//
// @api private
CollectionView.prototype.attachCollection = function () {
  this.listenTo(this.collection, 'reset', this.renderOnReset)
  this.listenTo(this.collection, 'add', this.renderOnAdd)
  this.listenTo(this.collection, 'remove', this.removeItem)
  return (this.empty = !this.collection.length)
}

CollectionView.prototype.detachCollection = function () {
  return this.stopListening(this.collection)
}

CollectionView.prototype.switchCollection = function (collection) {
  this.detachCollection()
  this.collection = collection
  return this.attachCollection()
}

// Ensures item views are removed properly
//
// @param {Array} models - array of Backbone.Models
// @api private
CollectionView.prototype.removePreviousItems = function (models) {
  let i, len, model, ref
  const results = []
  for (i = 0, len = models.length; i < len; i++) {
    model = models[i]
    results.push((ref = model.view) != null ? ref.remove() : void 0)
  }
  return results
}

CollectionView.prototype.renderOnReset = function (models, options) {
  this.empty = !this.collection.length
  this.removePreviousItems(options.previousModels)
  return this.render()
}

// Renders all collection items
//
// @api private
CollectionView.prototype.renderItems = function () {
  this.collection.each(this.renderItem.bind(this))
  return this.trigger('renderedItems')
}

// Removes an item
//
// @param {Backbone.Model} model
// @api private
CollectionView.prototype.removeItem = function (model) {
  this.empty = !this.collection.length
  if (this.empty) {
    return this.render()
  } else {
    return model.view.remove()
  }
}

// Ensures main template is rerendered when the first items are added
//
// @param {Backbone.Model} model
// @api private
CollectionView.prototype.renderOnAdd = function (model) {
  if (this.empty) {
    this.render()
  }
  this.empty = false
  return this.renderItem(model)
}

// Renders an item with the `itemView`
//
// @param {Backbone.Model} model
// @api private
CollectionView.prototype.renderItem = function (model) {
  const view = this.createItemView(model)
  view.render()
  if (typeof this.attachItemView === 'function') {
    this.attachItemView(model, view)
  }
  return this.insertView(view)
}

// Creates the item view instance, extend this when you need to do things
// like instantiate with child views, etc.
CollectionView.prototype.createItemView = function (model) {
  // eslint-disable-next-line new-cap
  const view = new this.itemView(
    $.extend({}, this.itemViewOptions || {}, {
      model,
    })
  )
  model.itemView = view
  return view
}

// Inserts the item view with respect to the collection comparator.
//
// @param {Backbone.View} view
// @api private
CollectionView.prototype.insertView = function (view) {
  const index = this.collection.indexOf(view.model)
  if (index === 0) {
    return this.prependView(view)
  } else if (index === this.collection.length - 1) {
    return this.appendView(view)
  } else {
    return this.insertViewAtIndex(view, index)
  }
}

CollectionView.prototype.insertViewAtIndex = function (view, index) {
  const $sibling = this.$list.children().eq(index)
  if ($sibling.length) {
    return $sibling.before(view.el)
  } else {
    return this.$list.append(view.el)
  }
}

CollectionView.prototype.prependView = function (view) {
  return this.$list.prepend(view.el)
}

CollectionView.prototype.appendView = function (view) {
  return this.$list.append(view.el)
}

export default CollectionView
