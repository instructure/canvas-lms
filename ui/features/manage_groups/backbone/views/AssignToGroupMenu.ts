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

import PopoverMenuView from './PopoverMenuView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from '../../jst/assignToGroupMenu.handlebars'
import $ from 'jquery'
import groupHasSubmissions from '../../groupHasSubmissions'
import '../../jquery/outerclick'

export default class AssignToGroupMenu extends PopoverMenuView {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.prototype.defaults = {...PopoverMenuView.prototype.defaults, zIndex: 10}

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      // @ts-expect-error - Backbone View property
      ...PopoverMenuView.prototype.events,
      'click .set-group': 'setGroup',
      'focusin .focus-bound': 'boundFocused',
    }

    // @ts-expect-error - Backbone View property
    this.prototype.tagName = 'div'

    // @ts-expect-error - Backbone View property
    this.prototype.className =
      'assign-to-group-menu ui-tooltip popover right content-top horizontal'

    // @ts-expect-error - Backbone View property
    this.prototype.template = template
  }

  attach() {
    // @ts-expect-error - Backbone View property
    return this.collection.on('change add remove reset', this.render, this)
  }

  // @ts-expect-error - Legacy Backbone typing
  setGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const newGroupId = $(e.currentTarget).data('group-id')
    // @ts-expect-error - Backbone View property
    const userId = this.model.id

    // @ts-expect-error - Backbone View property
    if (groupHasSubmissions(this.collection.get(newGroupId))) {
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
          return this.moveUser(newGroupId)
        } else {
          $(`[data-user-id='user_${userId}']`).focus()
          return this.hide()
        }
      })
    } else {
      return this.moveUser(newGroupId)
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  moveUser(newGroupId) {
    // @ts-expect-error - Backbone View property
    this.collection.category.reassignUser(this.model, this.collection.get(newGroupId))
    // @ts-expect-error - Backbone View property
    this.$el.detach()
    // @ts-expect-error - Backbone View property
    return this.trigger('close', {userMoved: true})
  }

  toJSON() {
    // @ts-expect-error - Backbone View property
    const hasGroups = this.collection.length > 0
    return {
      // @ts-expect-error - Backbone View property
      groups: this.collection.toJSON(),
      noGroups: !hasGroups,
      // @ts-expect-error - Backbone View property
      allFull: hasGroups && this.collection.models.every(g => g.isFull()),
    }
  }

  attachElement() {
    // @ts-expect-error - Backbone View property
    $('body').append(this.$el)
  }

  focus() {
    const noGroupsToJoin =
      // @ts-expect-error - Backbone View property
      this.collection.length <= 0 || this.collection.models.every(g => g.isFull())
    const toFocus = noGroupsToJoin ? '.popover-content p' : 'li a' // focus text if no groups, focus first group if groups
    // @ts-expect-error - Backbone View property
    return this.$el.find(toFocus).first().focus()
  }

  boundFocused() {
    // force hide and pretend we pressed escape
    // @ts-expect-error - Backbone View property
    this.$el.detach()
    // @ts-expect-error - Backbone View property
    return this.trigger('close', {escapePressed: true})
  }
}
AssignToGroupMenu.initClass()
