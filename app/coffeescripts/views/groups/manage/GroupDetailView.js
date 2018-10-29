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

import I18n from 'i18n!GroupDetailView'
import $ from 'jquery'
import {View} from 'Backbone'
import GroupEditView from './GroupEditView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import template from 'jst/groups/manage/groupDetail'
import groupHasSubmissions from '../../../util/groupHasSubmissions'
import '../../../jquery.rails_flash_notifications'
import 'jsx/context_cards/StudentContextCardTrigger'

export default class GroupDetailView extends View {
  static initClass() {
    this.optionProperty('users')

    this.prototype.template = template

    this.prototype.events = {
      'click .edit-group': 'editGroup',
      'click .delete-group': 'deleteGroup'
    }

    this.prototype.els = {
      '.toggle-group': '$toggleGroup',
      '.al-trigger': '$groupActions',
      '.edit-group': '$editGroupLink'
    }
  }

  attach() {
    return this.model.on('change', this.render)
  }

  summary() {
    const count = this.model.usersCount()
    if (this.model.theLimit()) {
      if (ENV.group_user_type === 'student') {
        return I18n.t('%{count} / %{max} students', {count, max: this.model.theLimit()})
      } else {
        return I18n.t('%{count} / %{max} users', {count, max: this.model.theLimit()})
      }
    } else if (ENV.group_user_type === 'student') {
      return I18n.t('student_count', 'student', {count})
    } else {
      return I18n.t('user_count', 'user', {count})
    }
  }

  editGroup(e) {
    e.preventDefault()
    if (this.editView == null)
      this.editView = new GroupEditView({
        model: this.model,
        groupCategory: this.model.collection.category
      })
    this.editView.setTrigger(this.$editGroupLink)
    return this.editView.open()
  }

  deleteGroup(e) {
    e.preventDefault()
    if (confirm(I18n.t('delete_confirm', 'Are you sure you want to remove this group?'))) {
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
            return this.performDeleteGroup()
          } else {
            return this.$groupActions.focus()
          }
        })
      } else {
        return this.performDeleteGroup()
      }
    } else {
      return this.$groupActions.focus()
    }
  }

  performDeleteGroup() {
    return this.model.destroy({
      success() {
        return $.flashMessage(I18n.t('flash.removed', 'Group successfully removed.'))
      },
      error() {
        return $.flashError(
          I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.')
        )
      }
    })
  }

  closeMenu() {
    return __guard__(this.$groupActions.data('kyleMenu'), x => x.$menu.popup('close'))
  }

  course_id() {
    return this.model.get('course_id')
  }

  toJSON() {
    const json = this.model.toJSON()
    json.leader = this.model.get('leader')
    json.canAssignUsers = ENV.IS_LARGE_ROSTER && !this.model.isLocked()
    json.canEdit = !this.model.isLocked()
    json.summary = this.summary()
    return json
  }
}
GroupDetailView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
