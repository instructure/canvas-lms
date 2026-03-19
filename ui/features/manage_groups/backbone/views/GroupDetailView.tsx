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

import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import GroupModal from '@canvas/group-modal'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from '../../jst/groupDetail.handlebars'
import groupHasSubmissions from '../../groupHasSubmissions'
import '@canvas/rails-flash-notifications'
import '@canvas/context-cards/react/StudentContextCardTrigger'

const I18n = createI18nScope('GroupDetailView')

export default class GroupDetailView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.optionProperty('users')

    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      'click .edit-group': 'editGroup',
      'click .delete-group': 'deleteGroup',
    }

    // @ts-expect-error - Backbone View property
    this.prototype.els = {
      '.toggle-group': '$toggleGroup',
      '.al-trigger': '$groupActions',
      '.edit-group': '$editGroupLink',
    }
  }

  attach() {
    // @ts-expect-error - Backbone View property
    return this.model.on('change', this.render, this)
  }

  refreshCollection() {
    // fetch a new paginated set of models for this collection from the server
    // helpul when bypassing Backbone lifecycle events
    // @ts-expect-error - Backbone View property
    this.model.collection.fetch()
  }

  summary() {
    // @ts-expect-error - Backbone View property
    const count = this.model.usersCount()
    // @ts-expect-error - Backbone View property
    if (this.model.theLimit()) {
      // @ts-expect-error - Backbone View property
      if (ENV.group_user_type === 'student') {
        // @ts-expect-error - Backbone View property
        return I18n.t('%{count} / %{max} students', {count, max: this.model.theLimit()})
      } else {
        // @ts-expect-error - Backbone View property
        return I18n.t('%{count} / %{max} users', {count, max: this.model.theLimit()})
      }
      // @ts-expect-error - Backbone View property
    } else if (ENV.group_user_type === 'student') {
      return I18n.t('student_count', 'student', {count})
    } else {
      return I18n.t('user_count', 'user', {count})
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  editGroup(e, open = true) {
    if (e) e.preventDefault()

    ReactDOM.render(
      // @ts-expect-error - Legacy Backbone typing
      <GroupModal
        group={{
          // @ts-expect-error - Backbone View property
          name: this.model.get('name'),
          // @ts-expect-error - Backbone View property
          id: this.model.get('id'),
          // @ts-expect-error - Backbone View property
          group_category_id: this.model.get('group_category_id'),
          // @ts-expect-error - Backbone View property
          role: this.model.get('role'),
          // @ts-expect-error - Backbone View property
          join_level: this.model.get('join_level'),
          // @ts-expect-error - Backbone View property
          group_limit: this.model.get('max_membership'),
          // @ts-expect-error - Backbone View property
          members_count: this.model.get('members_count'),
        }}
        label={I18n.t('Edit Group')}
        open={open}
        requestMethod="PUT"
        onSave={() => this.refreshCollection()}
        onDismiss={() => {
          this.editGroup(null, false)
          // @ts-expect-error - Backbone View property
          this.$editGroupLink.focus()
        }}
      />,
      document.getElementById('group-mount-point'),
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  deleteGroup(e) {
    e.preventDefault()

    if (confirm(I18n.t('delete_confirm', 'Are you sure you want to remove this group?'))) {
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
            return this.performDeleteGroup()
          } else {
            // @ts-expect-error - Backbone View property
            return this.$groupActions.focus()
          }
        })
      } else {
        return this.performDeleteGroup()
      }
    } else {
      // @ts-expect-error - Backbone View property
      return this.$groupActions.focus()
    }
  }

  performDeleteGroup() {
    // @ts-expect-error - Backbone View property
    return this.model.destroy({
      success() {
        return $.flashMessage(I18n.t('flash.removed', 'Group successfully removed.'))
      },
      error() {
        return $.flashError(
          I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.'),
        )
      },
    })
  }

  closeMenu() {
    // @ts-expect-error - Backbone View property
    return __guard__(this.$groupActions.data('kyleMenu'), x => x.$menu.popup('close'))
  }

  course_id() {
    // @ts-expect-error - Backbone View property
    return this.model.get('course_id')
  }

  toJSON() {
    // @ts-expect-error - Backbone View property
    const json = this.model.toJSON()
    // @ts-expect-error - Backbone View property
    json.leader = this.model.get('leader')
    // @ts-expect-error - Backbone View property
    json.canAssignUsers = ENV.IS_LARGE_ROSTER && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.canManage = ENV.permissions.can_manage_groups && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.canDelete = ENV.permissions.can_delete_groups && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.isNonCollaborative = this.model.get('non_collaborative')
    json.summary = this.summary()
    return json
  }
}
GroupDetailView.initClass()

// @ts-expect-error - Legacy Backbone typing
function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
