//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import {View} from '@canvas/backbone'
import template from '../../jst/group.handlebars'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import groupHasSubmissions from '../../groupHasSubmissions'

export default class GroupView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.prototype.tagName = 'li'

    // @ts-expect-error - Backbone View property
    this.prototype.className = 'group'

    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.optionProperty('expanded')

    // @ts-expect-error - Backbone View property
    this.optionProperty('addUnassignedMenu')

    // @ts-expect-error - Backbone View property
    this.child('groupUsersView', '[data-view=groupUsers]')
    // @ts-expect-error - Backbone View property
    this.child('groupDetailView', '[data-view=groupDetail]')

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      'click .toggle-group': 'toggleDetails',
      'click .add-user': 'showAddUser',
      'focus .add-user': 'showAddUser',
      'blur .add-user': 'hideAddUser',
    }

    // @ts-expect-error - Backbone View property
    this.prototype.dropOptions = {
      accept: '.group-user',
      activeClass: 'droppable',
      hoverClass: 'droppable-hover',
      tolerance: 'pointer',
    }
  }

  attributes() {
    // @ts-expect-error - Backbone View property
    return {'data-id': this.model.id}
  }

  attach() {
    // @ts-expect-error - Backbone View property
    this.expanded = false
    // @ts-expect-error - Backbone View property
    this.users = this.model.users()
    // @ts-expect-error - Backbone View property
    this.model.on('destroy', this.remove, this)
    // @ts-expect-error - Backbone View property
    this.model.on('change:members_count', this.updateFullState, this)
    // @ts-expect-error - Backbone View property
    return this.model.on('change:max_membership', this.updateFullState, this)
  }

  afterRender() {
    // @ts-expect-error - Backbone View property
    this.$el.toggleClass('group-expanded', this.expanded)
    // @ts-expect-error - Backbone View property
    this.$el.toggleClass('group-collapsed', !this.expanded)
    // @ts-expect-error - Backbone View property
    this.groupDetailView.$toggleGroup.attr('aria-expanded', `${this.expanded}`)
    return this.updateFullState()
  }

  updateFullState() {
    // @ts-expect-error - Backbone View property
    if (this.model.isLocked()) return
    // @ts-expect-error - Backbone View property
    if (this.model.isFull()) {
      // @ts-expect-error - Backbone View property
      if (this.$el.data('droppable')) this.$el.droppable('destroy')
      // @ts-expect-error - Backbone View property
      return this.$el.addClass('slots-full')
    } else {
      // enable droppable on the child GroupView (view)
      // @ts-expect-error - Backbone View property
      if (!this.$el.data('droppable')) {
        // @ts-expect-error - Backbone View property
        this.$el.droppable({...this.dropOptions}).on('drop', this._onDrop.bind(this))
      }
      // @ts-expect-error - Backbone View property
      return this.$el.removeClass('slots-full')
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  toggleDetails(e) {
    e.preventDefault()
    // @ts-expect-error - Backbone View property
    this.expanded = !this.expanded
    // @ts-expect-error - Backbone View property
    if (this.expanded && !this.users.loaded) {
      // @ts-expect-error - Backbone View property
      this.users.load(this.model.usersCount() ? 'all' : 'none')
    }
    return this.afterRender()
  }

  // @ts-expect-error - Legacy Backbone typing
  showAddUser(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    // @ts-expect-error - Backbone View property
    this.addUnassignedMenu.group = this.model
    // @ts-expect-error - Backbone View property
    return this.addUnassignedMenu.showBy($target, e.type === 'click')
  }

  // @ts-expect-error - Legacy Backbone typing
  hideAddUser(_e) {
    // @ts-expect-error - Backbone View property
    return this.addUnassignedMenu.hide()
  }

  closeMenus() {
    // @ts-expect-error - Backbone View property
    this.groupDetailView.closeMenu()
    // @ts-expect-error - Backbone View property
    return this.groupUsersView.closeMenus()
  }

  // @ts-expect-error - Legacy Backbone typing
  groupsAreDifferent(user) {
    // @ts-expect-error - Backbone View property
    return !user.has('group') || user.get('group').get('id') !== this.model.get('id')
  }

  // @ts-expect-error - Legacy Backbone typing
  eitherGroupHasSubmission(user) {
    return (
      (user.has('group') && groupHasSubmissions(user.get('group'))) ||
      // @ts-expect-error - Backbone View property
      groupHasSubmissions(this.model)
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  isUnassignedUserWithSubmission(user) {
    return (
      !user.has('group') &&
      user.has('group_submissions') &&
      user.get('group_submissions').length > 0
    )
  }

  // #
  // handle drop events on a GroupView
  // e - Event object.
  //   e.currentTarget - group the user is dropped on
  // ui - jQuery UI object.
  //   ui.draggable - the user being dragged
  // @ts-expect-error - Legacy Backbone typing
  _onDrop(e, ui) {
    const user = ui.draggable.data('model')
    const diffGroupsWithSubmission =
      this.groupsAreDifferent(user) && this.eitherGroupHasSubmission(user)
    const unassignedWithSubmission =
      // @ts-expect-error - Backbone View property
      this.isUnassignedUserWithSubmission(user) && this.model.usersCount() > 0

    if (diffGroupsWithSubmission || unassignedWithSubmission) {
      // @ts-expect-error - Backbone View property
      this.cloneCategoryView = new GroupCategoryCloneView({
        // @ts-expect-error - Backbone View property
        model: this.model.collection.category,
        openedFromCaution: true,
      })
      // @ts-expect-error - Backbone View property
      this.cloneCategoryView.open()
      // @ts-expect-error - Backbone View property
      return this.cloneCategoryView.on('close', () => {
        // @ts-expect-error - Backbone View property
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
          // @ts-expect-error - Backbone View property
        } else if (this.cloneCategoryView.changeGroups) {
          return this.moveUser(e, user)
        }
      })
    } else {
      return this.moveUser(e, user)
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  moveUser(e, user) {
    const newGroupId = $(e.currentTarget).data('id')
    return setTimeout(() =>
      // @ts-expect-error - Backbone View property
      this.model.collection.category.reassignUser(user, this.model.collection.get(newGroupId)),
    )
  }
}
GroupView.initClass()
