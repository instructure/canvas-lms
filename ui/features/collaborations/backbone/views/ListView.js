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
import $ from 'jquery'
import {each, extend as lodashExtend, flatten, reject} from 'lodash'
import PaginatedView from '@canvas/pagination/backbone/views/PaginatedView'
import UserCollection from '@canvas/users/backbone/collections/UserCollection'
import GroupCollection from '@canvas/groups/backbone/collections/GroupCollection'
import collaboratorTemplate from '../../jst/collaborator.handlebars'

extend(ListView, PaginatedView)

function ListView() {
  this.renderCollaborator = this.renderCollaborator.bind(this)
  this.render = this.render.bind(this)
  return ListView.__super__.constructor.apply(this, arguments)
}

ListView.prototype.filteredMembers = []

ListView.prototype.events = {
  'click a': 'selectCollaborator',
}

ListView.prototype.initialize = function (options) {
  if (options == null) {
    options = {}
  }
  this.collection = this.createCollection(options.type)
  this.paginationScrollContainer = this.$el.parents('.list-wrapper')
  this.attachEvents()
  return ListView.__super__.initialize.apply(this, arguments)
}

// Internal: Create a collection of the given type.
//
// type - The string name of the collection type (default: 'user').
//
// Returns a UserCollection or GroupCollection.
ListView.prototype.createCollection = function (type) {
  if (type == null) {
    type = 'user'
  }
  if (type === 'user') {
    const c = new UserCollection()
    c.comparator = 'sortable_name'
    return c
  } else {
    const collection = new GroupCollection()
    collection.forCourse = true
    return collection
  }
}

// Internal: Attach events to the collection.
//
// Returns nothing.
ListView.prototype.attachEvents = function () {
  return this.collection
    .on('add remove reset', this.render)
    .on(
      'remove',
      (function (_this) {
        return function (model) {
          return _this.trigger('collection:remove', model)
        }
      })(this)
    )
    .on(
      'reset',
      (function (_this) {
        return function () {
          return _this.trigger('collection:reset')
        }
      })(this)
    )
}

ListView.prototype.render = function () {
  this.updateFilter([])
  const collaboratorsHtml = this.collection.map(this.renderCollaborator).join('')
  this.$el.html(collaboratorsHtml)
  if (this.currentIndex != null && this.hasFocus) {
    this.updateFocus()
  }
  this.hasFocus = false
  return ListView.__super__.render.apply(this, arguments)
}

// Internal: Return HTML for the given collaborator.
//
// Returns an HTML string.
ListView.prototype.renderCollaborator = function (collaborator) {
  const binding = lodashExtend(collaborator.toJSON(), {
    name: collaborator.get('sortable_name') || collaborator.get('name'),
    type: collaborator.modelType,
    collaborator_id: collaborator.id,
  })
  return collaboratorTemplate(binding)
}

// Internal: Set focus after render.
//
// Returns nothing.
ListView.prototype.updateFocus = function () {
  let $target = $(this.$el.find('li').get(this.currentIndex)).find('a')
  if ($target.length === 0) {
    $target = $(this.$el.find('li').get(this.currentIndex - 1)).find('a')
  }
  if ($target.length === 0) {
    $target = this.$el.parents('.collaborator-picker').find('.members-list')
  }
  return $target.focus()
}

// Internal: Select a collaborator and remove them from the collection.
//
// Returns nothing.
ListView.prototype.selectCollaborator = function (e) {
  e.preventDefault()
  const id = $(e.currentTarget).attr('data-id')
  this.currentIndex = $(e.currentTarget).parent().index()
  this.hasFocus = true
  return this.collection.remove(id)
}

// Public: Filter out the given members. We wrap this in a setTimeout to
// allow Backbone to catch up with itself; without it, the occassional
// `cid of undefined` error crops up.
//
// models - An array of models to filter out of the collection.
//
// Returns nothing.
ListView.prototype.updateFilter = function (models) {
  return setTimeout(
    (function (_this) {
      return function () {
        _this.filteredMembers = flatten([_this.filteredMembers, models])
        each(_this.filteredMembers, function (m) {
          return _this.collection.remove(m, {
            silent: true,
          })
        })
        if (models.length > 0) {
          return _this.render()
        }
      }
    })(this),
    0
  )
}

// Public: Remove the given model from the filter.
//
// model - The model to remove from the filter.
//
// Returns nothing.
ListView.prototype.removeFromFilter = function (model) {
  return (this.filteredMembers = reject(this.filteredMembers, function (m) {
    return m.get('id') === model.get('id')
  }))
}

export default ListView
