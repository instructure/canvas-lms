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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {backbone, renderTray} from '@canvas/move-item-tray'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import GroupUserView from './GroupUserView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from '../../jst/groupUsers.handlebars'
import groupHasSubmissions from '../../groupHasSubmissions'
import 'jqueryui/draggable'
import 'jqueryui/droppable'

const I18n = useI18nScope('GroupUsersView')

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

    this.prototype.dragOptions = {
      appendTo: 'body',
      helper: 'clone',
      opacity: 0.75,
      refreshPositions: true,
      revert: 'invalid',
      revertDuration: 150,
      start(_event, _ui) {
        // hide AssignToGroupMenu (original and helper)
        $('.assign-to-group-menu').hide()
      },
    }

    this.prototype.template = template
  }

  initialize() {
    super.initialize(...arguments)
    if (this.collection.loadAll) return this.detachScroll()
  }

  attach() {
    this.model.on('change:members_count', this.render, this)
    this.model.on('change:leader', this.render, this)
    return this.collection.on('moved', this.highlightUser, this)
  }

  highlightUser(user) {
    return user.itemView.highlight()
  }

  closeMenus() {
    return this.collection.models.map(model => model.itemView.closeMenu())
  }

  removeUserFromGroup(userId) {
    const user = this.collection.getUser(userId)

    if (groupHasSubmissions(this.model)) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.model.collection.category,
        openedFromCaution: true,
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
        } else if (this.cloneCategoryView.changeGroups) {
          return this.removeUser(userId)
        } else {
          $(`#group-${this.model.id}-user-${user.id}-actions`).focus()
        }
      })
    } else {
      return this.removeUser(userId)
    }
  }

  removeUser(userId) {
    return this.collection.getUser(userId).save('group', null)
  }

  editGroupAssignment(userId) {
    const user = this.collection.getUser(userId)

    this.moveTrayProps = {
      title: I18n.t('Move Student'),
      items: [
        {
          id: user.get('id'),
          title: user.get('name'),
          groupId: this.model.get('id'),
        },
      ],
      moveOptions: {
        groupsLabel: I18n.t('Groups'),
        groups: backbone.collectionToGroups(this.model.collection, _col => ({models: []})),
        excludeCurrent: true,
      },
      onMoveSuccess: res => {
        const groupsHaveSubs =
          groupHasSubmissions(this.model) ||
          groupHasSubmissions(this.model.collection.get(res.groupId))
        const userHasSubs = __guard__(user.get('group_submissions'), x => x.length) > 0
        const newGroupNotEmpty = this.model.collection.get(res.groupId).usersCount() > 0
        if (groupsHaveSubs || (userHasSubs && newGroupNotEmpty)) {
          this.cloneCategoryView = new GroupCategoryCloneView({
            model: user.collection.category,
            openedFromCaution: true,
          })
          this.cloneCategoryView.open()
          return this.cloneCategoryView.on('close', () => {
            if (this.cloneCategoryView.cloneSuccess) {
              return window.location.reload()
            } else if (this.cloneCategoryView.changeGroups) {
              return this.moveUser(user, res.groupId)
            }
          })
        } else {
          return this.moveUser(user, res.groupId)
        }
      },

      focusOnExit: item =>
        document.querySelector(`.group[data-id=\"${item.groupId}\"] .group-heading`),
    }

    return renderTray(this.moveTrayProps, document.getElementById('not_right_side'))
  }

  moveUser(user, groupId) {
    return this.model.collection.category.reassignUser(user, this.model.collection.get(groupId))
  }

  toJSON() {
    return {
      count: this.model.usersCount(),
      locked: this.model.isLocked(),
      ENV,
    }
  }

  renderItem(model) {
    super.renderItem(...arguments)
    if (!(this.model != null ? this.model.isLocked() : undefined)) return this._initDrag(model.view)
  }

  // enable draggable on the child GroupUserView (view)
  _initDrag(view) {
    view.$el.draggable({...this.dragOptions})
    return view.$el.on('dragstart', (event, ui) => {
      ui.helper.css('width', view.$el.width())
      $(event.target).draggable('option', 'containment', 'document')
      $(event.target).data('draggable')._setContainment()
    })
  }

  removeItem(model) {
    return model.view.remove()
  }
}
GroupUsersView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
