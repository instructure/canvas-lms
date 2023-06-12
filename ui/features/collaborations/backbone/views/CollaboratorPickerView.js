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
import {View} from '@canvas/backbone'
import ListView from './ListView'
import MemberListView from './MemberListView'
import widgetTemplate from '../../jst/CollaboratorPicker.handlebars'

extend(CollaboratorPickerView, View)

function CollaboratorPickerView() {
  this.updateListFilters = this.updateListFilters.bind(this)
  this.deselectCollaborator = this.deselectCollaborator.bind(this)
  this.selectCollaborator = this.selectCollaborator.bind(this)
  return CollaboratorPickerView.__super__.constructor.apply(this, arguments)
}

CollaboratorPickerView.prototype.template = widgetTemplate

CollaboratorPickerView.prototype.events = {
  'change .filters input': 'filterList',
  'focus .filters input': 'focusRadioGroup',
  'blur .filters input': 'blurRadioGroup',
}

CollaboratorPickerView.prototype.fetchOptions = {
  data: {
    include_inactive: false,
    per_page: 50,
  },
}

CollaboratorPickerView.prototype.initialize = function () {
  CollaboratorPickerView.__super__.initialize.apply(this, arguments)
  this.cacheElements()
  this.createLists()
  this.attachEvents()
  return (this.includeGroups = !window.location.pathname.match(/groups/))
}

// Internal: Store references to DOM elements to avoid multiple lookups.
//
// Returns nothing.
CollaboratorPickerView.prototype.cacheElements = function () {
  this.$template = $(
    this.template({
      id: this.options.id || 'new',
    })
  )
  this.$userList = this.$template.find('.available-users')
  this.$groupList = this.$template.find('.available-groups')
  this.$memberList = this.$template.find('.members-list-wrapper')
  return (this.$listFilter = this.$template.find('.filters'))
}

// Internal: Attach events to child views.
//
// Returns nothing.
CollaboratorPickerView.prototype.attachEvents = function () {
  this.groupList.on('collection:remove', this.selectCollaborator)
  this.userList.on('collection:remove', this.selectCollaborator)
  this.memberList.on('collection:remove', this.deselectCollaborator)
  return this.memberList.on('collection:reset', this.updateListFilters)
}

// Internal: Create list sub-views.
//
// Returns nothing.
CollaboratorPickerView.prototype.createLists = function () {
  const currentUser = ENV.current_user_id && String(ENV.current_user_id)
  this.userList = new ListView({
    currentUser,
    el: this.$userList,
    fetchOptions: this.fetchOptions,
    type: 'user',
  })
  this.groupList = new ListView({
    el: this.$groupList,
    fetchOptions: this.fetchOptions,
    type: 'group',
  })
  return (this.memberList = new MemberListView({
    currentUser,
    el: this.$memberList,
  }))
}

// Internal: Trigger initial fetch actions on each collection.
//
// Returns nothing.
CollaboratorPickerView.prototype.fetchCollaborators = function () {
  this.userList.collection.url = ENV.POTENTIAL_COLLABORATORS_URL
  this.userList.collection.fetch(this.fetchOptions)
  if (this.includeGroups) {
    this.groupList.collection.fetch(this.fetchOptions)
  }
  if (this.options.edit) {
    this.memberList.collection.url = '/api/v1/collaborations/' + this.options.id + '/members'
    return (this.memberList.currentXHR = this.memberList.collection.fetch(this.fetchOptions))
  }
}

CollaboratorPickerView.prototype.render = function () {
  this.$el.append(this.$template)
  this.fetchCollaborators()
  if (this.includeGroups) {
    this.$listFilter.buttonset()
  } else {
    this.$listFilter.hide()
  }
  return this
}

// Internal: Filter available collaborators.
//
// e - Event object.
//
// Returns nothing.
CollaboratorPickerView.prototype.filterList = function (e) {
  const el = $(e.currentTarget).val()
  this.$el.find('.available-lists ul').hide()
  return this.$el.find('.' + el).show()
}

CollaboratorPickerView.prototype.focusRadioGroup = function (e) {
  return $(e.currentTarget).parent().addClass('radio-group-outline')
}

CollaboratorPickerView.prototype.blurRadioGroup = function (e) {
  return $(e.currentTarget).parent().removeClass('radio-group-outline')
}

CollaboratorPickerView.prototype.selectCollaborator = function (collaborator) {
  const item = collaborator.clone()
  item.set('collaborator_id', collaborator.id)
  item.set('id', collaborator.modelType + '_' + collaborator.id)
  return this.memberList.collection.add(item)
}

// Internal: Remove a collaborator and return them to their original list.
//
// collaborator - The model being removed from the collaborators list.
//
// Returns nothing.
CollaboratorPickerView.prototype.deselectCollaborator = function (collaborator) {
  const item = collaborator.clone()
  item.set('id', collaborator.get('collaborator_id'))
  const list = collaborator.modelType === 'user' ? this.userList : this.groupList
  list.removeFromFilter(item)
  return list.collection.add(item)
}

// Internal: Pass filter updates to the right collection.
//
// type   - The string type of the collection (e.g. 'user' or 'group').
// models - An array of models to update the filter with.
//
// Returns nothing.
CollaboratorPickerView.prototype.updateListFilters = function (type, models) {
  const list = type === 'user' ? this.userList : this.groupList
  return list.updateFilter(models)
}

export default CollaboratorPickerView
