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
    this.prototype.tagName = 'li'

    this.prototype.className = 'group'

    this.prototype.template = template

    this.optionProperty('expanded')

    this.optionProperty('addUnassignedMenu')

    this.child('groupUsersView', '[data-view=groupUsers]')
    this.child('groupDetailView', '[data-view=groupDetail]')

    this.prototype.events = {
      'click .toggle-group': 'toggleDetails',
      'click .add-user': 'showAddUser',
      'focus .add-user': 'showAddUser',
      'blur .add-user': 'hideAddUser',
    }

    this.prototype.dropOptions = {
      accept: '.group-user',
      activeClass: 'droppable',
      hoverClass: 'droppable-hover',
      tolerance: 'pointer',
    }
  }

  attributes() {
    return {'data-id': this.model.id}
  }

  attach() {
    this.expanded = false
    this.users = this.model.users()
    this.model.on('destroy', this.remove, this)
    this.model.on('change:members_count', this.updateFullState, this)
    return this.model.on('change:max_membership', this.updateFullState, this)
  }

  afterRender() {
    this.$el.toggleClass('group-expanded', this.expanded)
    this.$el.toggleClass('group-collapsed', !this.expanded)
    this.groupDetailView.$toggleGroup.attr('aria-expanded', `${this.expanded}`)
    return this.updateFullState()
  }

  updateFullState() {
    if (this.model.isLocked()) return
    if (this.model.isFull()) {
      if (this.$el.data('droppable')) this.$el.droppable('destroy')
      return this.$el.addClass('slots-full')
    } else {
      // enable droppable on the child GroupView (view)
      if (!this.$el.data('droppable')) {
        this.$el.droppable({...this.dropOptions}).on('drop', this._onDrop.bind(this))
      }
      return this.$el.removeClass('slots-full')
    }
  }

  toggleDetails(e) {
    e.preventDefault()
    this.expanded = !this.expanded
    if (this.expanded && !this.users.loaded) {
      this.users.load(this.model.usersCount() ? 'all' : 'none')
    }
    return this.afterRender()
  }

  showAddUser(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    this.addUnassignedMenu.group = this.model
    return this.addUnassignedMenu.showBy($target, e.type === 'click')
  }

  hideAddUser(_e) {
    return this.addUnassignedMenu.hide()
  }

  closeMenus() {
    this.groupDetailView.closeMenu()
    return this.groupUsersView.closeMenus()
  }

  groupsAreDifferent(user) {
    return !user.has('group') || user.get('group').get('id') !== this.model.get('id')
  }

  eitherGroupHasSubmission(user) {
    return (
      (user.has('group') && groupHasSubmissions(user.get('group'))) ||
      groupHasSubmissions(this.model)
    )
  }

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
  _onDrop(e, ui) {
    const user = ui.draggable.data('model')
    const diffGroupsWithSubmission =
      this.groupsAreDifferent(user) && this.eitherGroupHasSubmission(user)
    const unassignedWithSubmission =
      this.isUnassignedUserWithSubmission(user) && this.model.usersCount() > 0

    if (diffGroupsWithSubmission || unassignedWithSubmission) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.model.collection.category,
        openedFromCaution: true,
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
        } else if (this.cloneCategoryView.changeGroups) {
          return this.moveUser(e, user)
        }
      })
    } else {
      return this.moveUser(e, user)
    }
  }

  moveUser(e, user) {
    const newGroupId = $(e.currentTarget).data('id')
    return setTimeout(() =>
      this.model.collection.category.reassignUser(user, this.model.collection.get(newGroupId))
    )
  }
}
GroupView.initClass()
