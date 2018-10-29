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

import I18n from 'i18n!groups'
import $ from 'jquery'
import {View} from 'Backbone'
import MessageStudentsDialog from '../../MessageStudentsDialog'
import RandomlyAssignMembersView from './RandomlyAssignMembersView'
import GroupCreateView from './GroupCreateView'
import GroupCategoryEditView from './GroupCategoryEditView'
import GroupCategoryCloneView from './GroupCategoryCloneView'
import Group from '../../../models/Group'
import template from 'jst/groups/manage/groupCategoryDetail'

export default class GroupCategoryDetailView extends View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.deleteCategory = this.deleteCategory.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.template = template

    this.optionProperty('parentView')

    this.prototype.events = {
      'click .message-all-unassigned': 'messageAllUnassigned',
      'click .edit-category': 'editCategory',
      'click .delete-category': 'deleteCategory',
      'click .add-group': 'addGroup',
      'click .clone-category': 'cloneCategory'
    }

    this.prototype.els = {
      '.randomly-assign-members': '$randomlyAssignMembersLink',
      '.al-trigger': '$groupCategoryActions',
      '.edit-category': '$editGroupCategoryLink',
      '.message-all-unassigned': '$messageAllUnassignedLink',
      '.add-group': '$addGroupButton'
    }
  }

  initialize(options) {
    super.initialize(...arguments)
    return (this.randomlyAssignUsersView = new RandomlyAssignMembersView({
      model: options.model
    }))
  }

  attach() {
    this.collection.on('add remove reset', this.render)
    return this.model.on('change', this.render)
  }

  afterRender() {
    // its trigger will not be rendered yet, set it manually
    this.randomlyAssignUsersView.setTrigger(this.$randomlyAssignMembersLink)
    // reassign the trigger for the createView modal if instantiated
    return this.createView != null ? this.createView.setTrigger(this.$addGroupButton) : undefined
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.canMessageMembers = this.model.canMessageUnassignedMembers()
    json.canAssignMembers = this.model.canAssignUnassignedMembers()
    json.locked = this.model.isLocked()
    return json
  }

  deleteCategory(e) {
    e.preventDefault()
    if (!confirm(I18n.t('delete_confirm', 'Are you sure you want to remove this group set?'))) {
      this.$groupCategoryActions.focus()
      return
    }
    return this.model.destroy({
      success() {
        return $.flashMessage(I18n.t('flash.removed', 'Group set successfully removed.'))
      },
      failure() {
        return $.flashError(
          I18n.t('flash.removeError', 'Unable to remove the group set. Please try again later.')
        )
      }
    })
  }

  addGroup(e) {
    e.preventDefault()
    if (this.createView == null) {
      this.createView = new GroupCreateView({
        groupCategory: this.model,
        trigger: this.$addGroupButton
      })
    }
    const newGroup = new Group({group_category_id: this.model.id}, {newAndEmpty: true})
    newGroup.once('sync', () => {
      return this.collection.add(newGroup)
    })
    this.createView.model = newGroup
    return this.createView.open()
  }

  editCategory() {
    if (this.editCategoryView == null) {
      this.editCategoryView = new GroupCategoryEditView({
        model: this.model,
        trigger: this.$editGroupCategoryLink
      })
    }
    return this.editCategoryView.open()
  }

  cloneCategory(e) {
    e.preventDefault()
    this.cloneCategoryView = new GroupCategoryCloneView({
      model: this.model,
      openedFromCaution: false
    })
    this.cloneCategoryView.open()
    return this.cloneCategoryView.on('close', () => {
      if (this.cloneCategoryView.cloneSuccess) {
        return window.location.reload()
      } else {
        return $(`#group-category-${this.model.id}-actions`).focus()
      }
    })
  }

  messageAllUnassigned(e) {
    e.preventDefault()
    const disabler = $.Deferred()
    this.parentView.$el.disableWhileLoading(disabler)
    disabler.done(() => {
      // display the dialog when all data is ready
      const students = this.model
        .unassignedUsers()
        .map(user => ({id: user.get('id'), short_name: user.get('short_name')}))
      const dialog = new MessageStudentsDialog({
        trigger: this.$messageAllUnassignedLink,
        context: this.model.get('name'),
        recipientGroups: [
          {
            name: I18n.t(
              'students_who_have_not_joined_a_group',
              'Students who have not joined a group'
            ),
            recipients: students
          }
        ]
      })
      return dialog.open()
    })
    const users = this.model.unassignedUsers()
    // get notified when last page is fetched and then open the dialog
    users.on('fetched:last', () => {
      return disabler.resolve()
    })
    // ensure all data is loaded before displaying dialog
    if (users.urls.next != null) {
      users.loadAll = true
      return users.fetch({page: 'next'})
    } else {
      return disabler.resolve()
    }
  }
}
GroupCategoryDetailView.initClass()
