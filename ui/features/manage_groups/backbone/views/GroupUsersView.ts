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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {backbone, renderTray} from '@canvas/move-item-tray'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import GroupUserView from './GroupUserView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from '../../jst/groupUsers.handlebars'
import groupHasSubmissions from '../../groupHasSubmissions'
import 'jqueryui/draggable'
import 'jqueryui/droppable'

const I18n = createI18nScope('GroupUsersView')

export default class GroupUsersView extends PaginatedCollectionView {
  static initClass() {
    this.prototype.defaults = {
      ...PaginatedCollectionView.prototype.defaults,
      itemView: GroupUserView,
      itemViewOptions: {
        canAssignToGroup: false,
        canEditGroupAssignment: true,
        markInactiveStudents: false,
      },
    }

    // @ts-expect-error - Backbone View property
    this.prototype.dragOptions = {
      appendTo: 'body',
      helper: 'clone',
      opacity: 0.75,
      refreshPositions: true,
      revert: 'invalid',
      revertDuration: 150,
      // @ts-expect-error - Legacy Backbone typing
      start(_event, _ui) {
        // hide AssignToGroupMenu (original and helper)
        $('.assign-to-group-menu').hide()
      },
    }

    this.prototype.template = template
  }

  initialize() {
    super.initialize(...arguments)
    // @ts-expect-error - Backbone View property
    if (this.collection.loadAll) return this.detachScroll()
  }

  attach() {
    // @ts-expect-error - Backbone View property
    this.model.on('change:members_count', this.render, this)
    // @ts-expect-error - Backbone View property
    this.model.on('change:leader', this.render, this)
    // @ts-expect-error - Backbone View property
    return this.collection.on('moved', this.highlightUser, this)
  }

  // @ts-expect-error - Legacy Backbone typing
  highlightUser(user) {
    return user.itemView.highlight()
  }

  closeMenus() {
    // @ts-expect-error - Backbone View property
    return this.collection.models.map(model => model.itemView.closeMenu())
  }

  // @ts-expect-error - Legacy Backbone typing
  removeUserFromGroup(userId) {
    // @ts-expect-error - Backbone View property
    const user = this.collection.getUser(userId)

    // @ts-expect-error - Backbone View property
    if (groupHasSubmissions(this.model)) {
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
          return this.removeUser(userId)
        } else {
          // @ts-expect-error - Backbone View property
          $(`#group-${this.model.id}-user-${user.id}-actions`).focus()
        }
      })
    } else {
      return this.removeUser(userId)
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  removeUser(userId) {
    // @ts-expect-error - Backbone View property
    return this.collection.getUser(userId).save('group', null)
  }

  // @ts-expect-error - Legacy Backbone typing
  editGroupAssignment(userId) {
    // @ts-expect-error - Backbone View property
    const user = this.collection.getUser(userId)

    // @ts-expect-error - Backbone View property
    this.moveTrayProps = {
      title: I18n.t('Move Student'),
      items: [
        {
          id: user.get('id'),
          title: user.get('name'),
          // @ts-expect-error - Backbone View property
          groupId: this.model.get('id'),
        },
      ],
      moveOptions: {
        groupsLabel: I18n.t('Groups'),
        // @ts-expect-error - Backbone View property
        groups: backbone.collectionToGroups(this.model.collection, _col => ({models: []})),
        excludeCurrent: true,
      },
      // @ts-expect-error - Legacy Backbone typing
      onMoveSuccess: res => {
        const groupsHaveSubs =
          // @ts-expect-error - Backbone View property
          groupHasSubmissions(this.model) ||
          // @ts-expect-error - Backbone View property
          groupHasSubmissions(this.model.collection.get(res.groupId))
        // @ts-expect-error - Legacy Backbone typing
        const userHasSubs = __guard__(user.get('group_submissions'), x => x.length) > 0
        // @ts-expect-error - Backbone View property
        const newGroupNotEmpty = this.model.collection.get(res.groupId).usersCount() > 0
        if (groupsHaveSubs || (userHasSubs && newGroupNotEmpty)) {
          // @ts-expect-error - Backbone View property
          this.cloneCategoryView = new GroupCategoryCloneView({
            model: user.collection.category,
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
              return this.moveUser(user, res.groupId)
            }
          })
        } else {
          return this.moveUser(user, res.groupId)
        }
      },

      // @ts-expect-error - Legacy Backbone typing
      focusOnExit: item =>
        document.querySelector(`.group[data-id=\"${item.groupId}\"] .group-heading`),
    }

    // @ts-expect-error - Backbone View property
    return renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
  }

  // @ts-expect-error - Legacy Backbone typing
  moveUser(user, groupId) {
    // @ts-expect-error - Backbone View property
    return this.model.collection.category.reassignUser(user, this.model.collection.get(groupId))
  }

  toJSON() {
    return {
      // @ts-expect-error - Backbone View property
      count: this.model.usersCount(),
      // @ts-expect-error - Backbone View property
      locked: this.model.isLocked(),
      ENV,
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  renderItem(model) {
    // @ts-expect-error - Backbone View property
    super.renderItem(...arguments)
    // @ts-expect-error - Backbone View property
    if (!(this.model != null ? this.model.isLocked() : undefined)) return this._initDrag(model.view)
  }

  // enable draggable on the child GroupUserView (view)
  // @ts-expect-error - Legacy Backbone typing
  _initDrag(view) {
    // @ts-expect-error - Backbone View property
    view.$el.draggable({...this.dragOptions})
    // @ts-expect-error - Legacy Backbone typing
    return view.$el.on('dragstart', (event, ui) => {
      ui.helper.css('width', view.$el.width())
      $(event.target).draggable('option', 'containment', 'document')
      $(event.target).data('draggable')._setContainment()
    })
  }

  // @ts-expect-error - Legacy Backbone typing
  removeItem(model) {
    return model.view.remove()
  }
}
GroupUsersView.initClass()

// @ts-expect-error - Legacy Backbone typing
function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
