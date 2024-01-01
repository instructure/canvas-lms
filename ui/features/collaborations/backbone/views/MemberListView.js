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

import {extend as backboneExtend} from '@canvas/backbone/utils'
import $ from 'jquery'
import {extend, filter, map} from 'lodash'
import {View} from '@canvas/backbone'
import Group from '@canvas/groups/backbone/models/Group'
import User from '@canvas/users/backbone/models/User'
import CollaboratorCollection from '../collections/CollaboratorCollection'
import collaboratorTemplate from '../../jst/collaborator.handlebars'

backboneExtend(MemberListView, View)

function MemberListView() {
  this.onFetch = this.onFetch.bind(this)
  this.publishCollection = this.publishCollection.bind(this)
  this.deselectCollaborator = this.deselectCollaborator.bind(this)
  this.render = this.render.bind(this)
  return MemberListView.__super__.constructor.apply(this, arguments)
}

MemberListView.prototype.events = {
  'click li a': 'removeCollaborator',
  'click .remove-all': 'removeAll',
}

MemberListView.prototype.initialize = function () {
  MemberListView.__super__.initialize.apply(this, arguments)
  this.collection = this.createCollection()
  this.cacheElements()
  return this.attachEvents()
}

// Internal: Create a new collection for use w/ this view.
//
// Returns a CollaboratorCollection.
MemberListView.prototype.createCollection = function () {
  return new CollaboratorCollection()
}

// Internal: Store DOM elements to avoid repeated lookups.
//
// Returns nothing.
MemberListView.prototype.cacheElements = function () {
  this.$list = this.$el.find('ul')
  this.$removeBtn = this.$el.find('.remove-button')
  return (this.$instructions = this.$el.find('.member-instructions'))
}

// Internal: Attach events to the collection.
//
// Returns nothing.
MemberListView.prototype.attachEvents = function () {
  return this.collection
    .on('add remove reset', this.render)
    .on('reset sync', this.onFetch)
    .on('remove', this.deselectCollaborator)
}

MemberListView.prototype.render = function () {
  this.updateElementVisibility()
  let collaboratorsHtml = this.collection.map(
    (function (_this) {
      return function (c) {
        return collaboratorTemplate(
          extend(c.toJSON(), {
            type: c.modelType || c.get('type'),
            collaborator_id: c.get('collaborator_id'),
            id: c.get('id'),
            name: c.get('sortable_name') || c.get('name'),
            selected: true,
          })
        )
      }
    })(this)
  )
  collaboratorsHtml = collaboratorsHtml.join('')
  this.$list.html(collaboratorsHtml)
  if (this.currentIndex != null && this.hasFocus) {
    this.updateFocus()
  }
  return (this.hasFocus = false)
}

// Internal: Manage focus on re-render.
//
// Returns nothing.
MemberListView.prototype.updateFocus = function () {
  let $target = $(this.$el.find('li').get(this.currentIndex)).find('a')
  if ($target.length === 0) {
    $target = $(this.$el.find('li').get(this.currentIndex - 1)).find('a')
  }
  if ($target.length === 0) {
    $target = this.$el.parents('.collaborator-picker').find('.list-wrapper:first ul:visible')
  }
  return $target.focus()
}

// Internal: Remove a collaborator from this list.
//
// e - Event object.
//
// Returns nothing.
MemberListView.prototype.removeCollaborator = function (e) {
  e.preventDefault()
  const id = $(e.currentTarget).attr('data-id')
  this.currentIndex = $(e.target).parent().index()
  this.hasFocus = true
  return this.collection.remove(id)
}

// Internal: Remove all current collaborators.
//
// e - Event object.
//
// Returns nothing.
MemberListView.prototype.removeAll = function (e) {
  e.preventDefault()
  this.collection.remove(this.collection.models)
  this.currentIndex = 0
  return this.updateFocus()
}

// Internal: Show/hide the remove all btn based on collection size.
//
// Returns nothing.
MemberListView.prototype.updateElementVisibility = function () {
  if (this.collection.length === 0) {
    this.$removeBtn.hide()
    return this.$instructions.show()
  } else {
    this.$removeBtn.show()
    return this.$instructions.hide()
  }
}

MemberListView.prototype.deselectCollaborator = function (model) {
  if (model.modelType == null) {
    model = this.typecastMember(model)
  }
  return this.trigger('collection:remove', model)
}

// Internal: Convert a collaborator into a user or group.
//
// model - The collaborator model to typecast.
//
// Returns a user or group model.
MemberListView.prototype.typecastMember = function (model) {
  const props = extend(model.toJSON(), {
    id: model.get('collaborator_id'),
  })
  if (model.get('type') === 'user') {
    return new User(
      extend(props, {
        sortable_name: props.name,
      })
    )
  } else {
    return new Group(props)
  }
}

// Internal: Publish contents of the collection.
//
// collection - The child collection.
//
// Returns nothing.
MemberListView.prototype.publishCollection = function (collection) {
  const users = collection.filter(function (m) {
    return m.get('type') === 'user'
  })
  const groups = collection.filter(function (m) {
    return m.get('type') === 'group'
  })
  this.trigger('collection:reset', 'user', map(users, this.typecastMember))
  return this.trigger('collection:reset', 'group', map(groups, this.typecastMember))
}

MemberListView.prototype.onFetch = function () {
  this.publishCollection(this.collection)
  const url = this.getNextPage(this.currentXHR.getResponseHeader('Link'))
  if (url) {
    this.collection.url = url
    this.currentXHR = this.collection.fetch({
      add: true,
    })
    return $.when(this.currentXHR).then(this.onFetch)
  }
}

MemberListView.prototype.getNextPage = function (header) {
  let nextPage
  if (header) {
    nextPage = filter(header.split(','), function (l) {
      return l.match(/next/)
    })[0]
  }
  if (nextPage) {
    return nextPage.match(/http[^>]+/)[0]
  } else {
    return false
  }
}

export default MemberListView
