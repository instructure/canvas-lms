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

import {View} from '@canvas/backbone'
import template from '../../jst/groupUser.handlebars'
import {GroupUserMenu} from '../../react/GroupUserMenu'
import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('GroupUsersView')

export default class GroupUserView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.optionProperty('canAssignToGroup')
    // @ts-expect-error - Backbone View property
    this.optionProperty('canEditGroupAssignment')

    // @ts-expect-error - Backbone View property
    this.prototype.tagName = 'li'

    // @ts-expect-error - Backbone View property
    this.prototype.className = 'group-user'

    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.prototype.els = {'.al-trigger': '$userActions'}
  }

  initialize() {
    // @ts-expect-error - Backbone View property
    this.parentView = arguments[0].model.collection.view
    super.initialize(...arguments)
  }

  closeMenu() {
    // @ts-expect-error - Backbone View property
    const userId = this.model.get('id')

    const event = new CustomEvent(`closeGroupUserMenuForUser${userId}`)
    window.dispatchEvent(event)
  }

  attach() {
    // @ts-expect-error - Backbone View property
    return this.model.on('change', this.render, this)
  }

  afterRender() {
    this.renderGroupUserMenu()
    // @ts-expect-error - Backbone View property
    return this.$el.data('model', this.model)
  }

  renderGroupUserMenu() {
    // @ts-expect-error - Backbone View property
    const userId = this.model.get('id')
    // @ts-expect-error - Backbone View property
    const userName = this.model.get('name')
    // @ts-expect-error - Backbone View property
    const group = this.model.get('group')
    const groupId = group && group.id

    // I want to remove this setTimeout, it is ugly. If I don't do this, it can't find the selector.
    setTimeout(() => {
      const groupUserMenuSelector = document.getElementById(
        `group_${groupId}_user_${userId}_menu_selector`,
      )
      // @ts-expect-error - Backbone View property
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
          groupUserMenuSelector,
        )
      }
    }, 0)
  }

  // @ts-expect-error - Legacy Backbone typing
  removeUserFromGroup(userId) {
    // @ts-expect-error - Backbone View property
    this.parentView.removeUserFromGroup(userId)
  }

  // @ts-expect-error - Legacy Backbone typing
  setAsLeader(userId) {
    // @ts-expect-error - Backbone View property
    const group = this.model.get('group')

    group.save(
      {leader: {id: userId}},
      {
        success: () => {
          $.screenReaderFlashMessage(
            // @ts-expect-error - Backbone View property
            I18n.t('%{user} is now group leader', {user: this.model.get('name')}),
          )

          setTimeout(() => {
            $(`[data-userid='${userId}']`).focus()
          }, 0)
        },
      },
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  removeAsLeader(userId) {
    // @ts-expect-error - Backbone View property
    const group = this.model.get('group')

    group.save(
      {leader: null},
      {
        success: () => {
          $.screenReaderFlashMessage(
            // @ts-expect-error - Backbone View property
            I18n.t('Removed %{user} as group leader', {user: this.model.get('name')}),
          )

          setTimeout(() => {
            $(`[data-userid='${userId}']`).focus()
          }, 0)
        },
      },
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  moveTo(userId) {
    // @ts-expect-error - Backbone View property
    this.parentView.editGroupAssignment(userId)
  }

  highlight() {
    // @ts-expect-error - Backbone View property
    this.$el.addClass('group-user-highlight')
    // @ts-expect-error - Backbone View property
    return setTimeout(() => this.$el.removeClass('group-user-highlight'), 1000)
  }

  toJSON() {
    // @ts-expect-error - Backbone View property
    const group = this.model.get('group')
    const result = {
      groupId: group && group.id,
      ...this,
      ...super.toJSON(...arguments),
    }
    result.shouldMarkInactive =
      // @ts-expect-error - Backbone View property
      this.options.markInactiveStudents && this.model.attributes.is_inactive
    result.isLeader = this.isLeader()
    return result
  }

  isLeader() {
    // @ts-expect-error - Backbone View property
    return this.model.get('group')?.get('leader')?.id === this.model.get('id')
  }
}
GroupUserView.initClass()
