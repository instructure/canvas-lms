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
    this.prototype.defaults = {...PopoverMenuView.prototype.defaults, zIndex: 10}

    this.prototype.events = {
      ...PopoverMenuView.prototype.events,
      'click .set-group': 'setGroup',
      'focusin .focus-bound': 'boundFocused',
    }

    this.prototype.tagName = 'div'

    this.prototype.className =
      'assign-to-group-menu ui-tooltip popover right content-top horizontal'

    this.prototype.template = template
  }

  attach() {
    return this.collection.on('change add remove reset', this.render, this)
  }

  setGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const newGroupId = $(e.currentTarget).data('group-id')
    const userId = this.model.id

    if (groupHasSubmissions(this.collection.get(newGroupId))) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.model.collection.category,
        openedFromCaution: true,
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
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

  moveUser(newGroupId) {
    this.collection.category.reassignUser(this.model, this.collection.get(newGroupId))
    this.$el.detach()
    return this.trigger('close', {userMoved: true})
  }

  toJSON() {
    const hasGroups = this.collection.length > 0
    return {
      groups: this.collection.toJSON(),
      noGroups: !hasGroups,
      allFull: hasGroups && this.collection.models.every(g => g.isFull()),
    }
  }

  attachElement() {
    $('body').append(this.$el)
  }

  focus() {
    const noGroupsToJoin =
      this.collection.length <= 0 || this.collection.models.every(g => g.isFull())
    const toFocus = noGroupsToJoin ? '.popover-content p' : 'li a' // focus text if no groups, focus first group if groups
    return this.$el.find(toFocus).first().focus()
  }

  boundFocused() {
    // force hide and pretend we pressed escape
    this.$el.detach()
    return this.trigger('close', {escapePressed: true})
  }
}
AssignToGroupMenu.initClass()
