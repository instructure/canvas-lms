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

/* eslint-disable no-void */

import {View} from '@canvas/backbone'
import template from '../../jst/groupUser.handlebars'
import {GroupUserMenu} from '../../react/GroupUserMenu'
import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('GroupUsersView')

export default class GroupUserView extends View {
  static initClass() {
    this.optionProperty('canAssignToGroup')
    this.optionProperty('canEditGroupAssignment')

    this.prototype.tagName = 'li'

    this.prototype.className = 'group-user'

    this.prototype.template = template

    this.prototype.els = {'.al-trigger': '$userActions'}
  }

  initialize() {
    this.parentView = arguments[0].model.collection.view
    super.initialize(...arguments)
  }

  closeMenu() {
    const userId = this.model.get('id')

    const event = new CustomEvent(`closeGroupUserMenuForUser${userId}`)
    window.dispatchEvent(event)
  }

  attach() {
    return this.model.on('change', this.render, this)
  }

  afterRender() {
    this.renderGroupUserMenu()
    return this.$el.data('model', this.model)
  }

  renderGroupUserMenu() {
    const userId = this.model.get('id')
    const userName = this.model.get('name')
    const group = this.model.get('group')
    const groupId = group && group.id

    // I want to remove this setTimeout, it is ugly. If I don't do this, it can't find the selector.
    setTimeout(() => {
      const groupUserMenuSelector = document.getElementById(
        `group_${groupId}_user_${userId}_menu_selector`
      )
      if (this.canEditGroupAssignment && groupUserMenuSelector) {
        ReactDOM.render(
          <GroupUserMenu
            userId={userId}
            userName={userName}
            isLeader={this.isLeader()}
            onRemoveFromGroup={this.removeUserFromGroup.bind(this)}
            onSetAsLeader={this.setAsLeader.bind(this)}
            onRemoveAsLeader={this.removeAsLeader.bind(this)}
            onMoveTo={this.moveTo.bind(this)}
          />,
          groupUserMenuSelector
        )
      }
    }, 0)
  }

  removeUserFromGroup(userId) {
    this.parentView.removeUserFromGroup(userId)
  }

  setAsLeader(userId) {
    const group = this.model.get('group')

    group.save(
      {leader: {id: userId}},
      {
        success: () => {
          $.screenReaderFlashMessage(
            I18n.t('%{user} is now group leader', {user: this.model.get('name')})
          )

          setTimeout(() => {
            $(`[data-userid='${userId}']`).focus()
          }, 0)
        },
      }
    )
  }

  removeAsLeader(userId) {
    const group = this.model.get('group')

    group.save(
      {leader: null},
      {
        success: () => {
          $.screenReaderFlashMessage(
            I18n.t('Removed %{user} as group leader', {user: this.model.get('name')})
          )

          setTimeout(() => {
            $(`[data-userid='${userId}']`).focus()
          }, 0)
        },
      }
    )
  }

  moveTo(userId) {
    this.parentView.editGroupAssignment(userId)
  }

  highlight() {
    this.$el.addClass('group-user-highlight')
    return setTimeout(() => this.$el.removeClass('group-user-highlight'), 1000)
  }

  toJSON() {
    const group = this.model.get('group')
    const result = {
      groupId: group && group.id,
      ...this,
      ...super.toJSON(...arguments),
    }
    result.shouldMarkInactive =
      this.options.markInactiveStudents && this.model.attributes.is_inactive
    result.isLeader = this.isLeader()
    return result
  }

  isLeader() {
    return this.model.get('group')?.get('leader')?.id === this.model.get('id')
  }
}
GroupUserView.initClass()
