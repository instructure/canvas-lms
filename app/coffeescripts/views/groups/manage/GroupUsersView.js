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

import I18n from 'i18n!GroupUsersView'
import $ from 'jquery'
import {backbone, renderTray} from 'jsx/move_item'
import PaginatedCollectionView from '../../PaginatedCollectionView'
import GroupUserView from './GroupUserView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from 'jst/groups/manage/groupUsers'
import groupHasSubmissions from '../../../util/groupHasSubmissions'
import 'jqueryui/draggable'
import 'jqueryui/droppable'

export default class GroupUsersView extends PaginatedCollectionView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.renderItem = this.renderItem.bind(this)
    this._initDrag = this._initDrag.bind(this)
    this.removeItem = this.removeItem.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.defaults = {
      ...PaginatedCollectionView.prototype.defaults,
      itemView: GroupUserView,
      itemViewOptions: {
        canAssignToGroup: false,
        canEditGroupAssignment: true,
        markInactiveStudents: false
      }
    }

    this.prototype.dragOptions = {
      appendTo: 'body',
      helper: 'clone',
      opacity: 0.75,
      refreshPositions: true,
      revert: 'invalid',
      revertDuration: 150,
      start(event, ui) {
        // hide AssignToGroupMenu (original and helper)
        $('.assign-to-group-menu').hide()
      }
    }

    this.prototype.template = template

    this.prototype.events = {
      'click .remove-from-group': 'removeUserFromGroup',
      'click .remove-as-leader': 'removeLeader',
      'click .set-as-leader': 'setLeader',
      'click .edit-group-assignment': 'editGroupAssignment'
    }
  }

  initialize() {
    super.initialize(...arguments)
    if (this.collection.loadAll) return this.detachScroll()
  }

  attach() {
    this.model.on('change:members_count', this.render)
    this.model.on('change:leader', this.render)
    return this.collection.on('moved', this.highlightUser)
  }

  highlightUser(user) {
    return user.itemView.highlight()
  }

  closeMenus() {
    return this.collection.models.map(model => model.itemView.closeMenu())
  }

  removeUserFromGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    const user = this.collection.getUser($target.data('user-id'))

    if (groupHasSubmissions(this.model)) {
      this.cloneCategoryView = new GroupCategoryCloneView({
        model: this.model.collection.category,
        openedFromCaution: true
      })
      this.cloneCategoryView.open()
      return this.cloneCategoryView.on('close', () => {
        if (this.cloneCategoryView.cloneSuccess) {
          return window.location.reload()
        } else if (this.cloneCategoryView.changeGroups) {
          return this.removeUser(e, $target)
        } else {
          $(`#group-${this.model.id}-user-${user.id}-actions`).focus()
        }
      })
    } else {
      return this.removeUser(e, $target)
    }
  }

  removeUser(e, $target) {
    return this.collection.getUser($target.data('user-id')).save('group', null)
  }

  removeLeader(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    const user_id = $target
      .data('user-id')
      .toString()
      .replace('user_', '')
    const user_name = this.model.get('leader').display_name
    return this.model.save(
      {leader: null},
      {
        success: () => {
          $.screenReaderFlashMessage(I18n.t('Removed %{user} as group leader', {user: user_name}))
          $(`.group-user-actions[data-user-id='user_${user_id}']`, this.el).focus()
        }
      }
    )
  }

  setLeader(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    const user_id = $target
      .data('user-id')
      .toString()
      .replace('user_', '')
    return this.model.save(
      {leader: {id: user_id}},
      {
        success: () => {
          $.screenReaderFlashMessage(
            I18n.t('%{user} is now group leader', {user: this.model.get('leader').display_name})
          )
          $(`.group-user-actions[data-user-id='user_${user_id}']`, this.el).focus()
        }
      }
    )
  }

  editGroupAssignment(e) {
    e.preventDefault()
    e.stopPropagation()

    const $target = $(e.currentTarget)
    const user = this.collection.getUser($target.data('user-id'))

    this.moveTrayProps = {
      title: I18n.t('Move Student'),
      items: [
        {
          id: user.get('id'),
          title: user.get('name'),
          groupId: this.model.get('id')
        }
      ],
      moveOptions: {
        groupsLabel: I18n.t('Groups'),
        groups: backbone.collectionToGroups(this.model.collection, col => ({models: []})),
        excludeCurrent: true
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
            openedFromCaution: true
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
        document.querySelector(`.group[data-id=\"${item.groupId}\"] .group-heading`)
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
      ENV
    }
  }

  renderItem(model) {
    super.renderItem(...arguments)
    if (!(this.model != null ? this.model.isLocked() : undefined)) return this._initDrag(model.view)
  }

  // enable draggable on the child GroupUserView (view)
  _initDrag(view) {
    view.$el.draggable(Object.assign({}, this.dragOptions))
    return view.$el.on('dragstart', (event, ui) => {
      ui.helper.css('width', view.$el.width())
      $(event.target).draggable('option', 'containment', 'document')
      $(event.target)
        .data('draggable')
        ._setContainment()
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
