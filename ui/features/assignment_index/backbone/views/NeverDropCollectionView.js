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

import $ from 'jquery'
import {extend} from '@canvas/backbone/utils'
import {debounce} from 'lodash'
import CollectionView from '@canvas/backbone-collection-view'
import NeverDropView from './NeverDropView'
import template from '../../jst/NeverDropCollection.handlebars'

extend(NeverDropCollectionView, CollectionView)

function NeverDropCollectionView() {
  this.triggerRender = this.triggerRender.bind(this)
  return NeverDropCollectionView.__super__.constructor.apply(this, arguments)
}

NeverDropCollectionView.prototype.itemView = NeverDropView

NeverDropCollectionView.prototype.template = template

NeverDropCollectionView.optionProperty('canChangeDropRules')

NeverDropCollectionView.prototype.events = {
  'click .add_never_drop': 'addNeverDrop',
}

NeverDropCollectionView.prototype.initialize = function () {
  // feed all events that should trigger a render
  // through a custom event so that we only render
  // once per batch of changes
  this.on('should-render', debounce(this.render, 100))
  return NeverDropCollectionView.__super__.initialize.apply(this, arguments)
}

NeverDropCollectionView.prototype.createItemView = function (model) {
  const options = {
    canChangeDropRules: this.canChangeDropRules,
  }
  // eslint-disable-next-line new-cap
  return new this.itemView(
    $.extend(
      {},
      this.itemViewOptions || {},
      {
        model,
      },
      options
    )
  )
}

NeverDropCollectionView.prototype.attachCollection = function (_options) {
  // listen to events on the collection that keeps track of what we can add
  this.collection.availableValues.on('add', this.triggerRender)
  this.collection.takenValues.on('add', this.triggerRender)
  this.collection.on('add', this.triggerRender)
  this.collection.on('remove', this.triggerRender)
  return this.collection.on('reset', this.triggerRender)
}

// define some attrs here so that we can
// use declarative translations in the template
NeverDropCollectionView.prototype.toJSON = function () {
  return {
    canChangeDropRules: this.canChangeDropRules,
    hasAssignments: this.collection.availableValues.length > 0,
    hasNeverDrops: this.collection.takenValues.length > 0,
  }
}

NeverDropCollectionView.prototype.triggerRender = function (_model, _collection, _options) {
  return this.trigger('should-render')
}

// add a new select, and mark it for focusing
// when we re-render the collection
NeverDropCollectionView.prototype.addNeverDrop = function (e) {
  e.preventDefault()
  if (this.canChangeDropRules) {
    const model = {
      label_id: this.collection.ag_id,
      focus: true,
    }
    return this.collection.add(model)
  }
}

export default NeverDropCollectionView
