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
import RandomlyAssignMembersView from './RandomlyAssignMembersView'
import GroupCategoryEditView from '@canvas/groups/backbone/views/GroupCategoryEditView'
import template from '../../jst/groupCategoryDetail.handlebars'
import GroupModal from '@canvas/group-modal'
import GroupCategoryCloneModal from '../../react/GroupCategoryCloneModal'
import GroupCategoryMessageAllUnassignedModal from '../../react/GroupCategoryMessageAllUnassignedModal'
import GroupImportModal from '../../react/GroupImportModal'

const I18n = createI18nScope('groups')

export default class GroupCategoryDetailView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.optionProperty('parentView')

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      'click .message-all-unassigned': 'messageAllUnassigned',
      'click .edit-category': 'editCategory',
      'click .delete-category': 'deleteCategory',
      'click .add-group': 'addGroup',
      'click .import-groups': 'importGroups',
      'click .clone-category': 'cloneCategory',
    }

    // @ts-expect-error - Backbone View property
    this.prototype.els = {
      '.randomly-assign-members': '$randomlyAssignMembersLink',
      '.al-trigger': '$groupCategoryActions',
      '.edit-category': '$editGroupCategoryLink',
      '.message-all-unassigned': '$messageAllUnassignedLink',
      '.add-group': '$addGroupButton',
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  initialize(options) {
    super.initialize(...arguments)
    // @ts-expect-error - Backbone View property
    return (this.randomlyAssignUsersView = new RandomlyAssignMembersView({
      model: options.model,
    }))
  }

  attach() {
    // @ts-expect-error - Backbone View property
    this.collection.on('add remove reset', this.render, this)
    // @ts-expect-error - Backbone View property
    return this.model.on('change', this.render, this)
  }

  afterRender() {
    // its trigger will not be rendered yet, set it manually
    // @ts-expect-error - Backbone View property
    this.randomlyAssignUsersView.setTrigger(this.$randomlyAssignMembersLink)
    // reassign the trigger for the createView modal if instantiated
    // @ts-expect-error - Backbone View property
    return this.createView != null ? this.createView.setTrigger(this.$addGroupButton) : undefined
  }

  refreshCollection() {
    // fetch a new paginated set of models for this collection from the server
    // helpul when bypassing Backbone lifecycle events
    // @ts-expect-error - Backbone View property
    this.collection.fetch()
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    // @ts-expect-error - Backbone View property
    json.canMessageMembers = this.model.canMessageUnassignedMembers()
    json.canAssignMembers =
      // @ts-expect-error - Backbone View property
      ENV.permissions.can_manage_groups && this.model.canAssignUnassignedMembers()
    // @ts-expect-error - Backbone View property
    json.locked = this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.canAdd = ENV.permissions.can_add_groups && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.canManage = ENV.permissions.can_manage_groups && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.canDelete = ENV.permissions.can_delete_groups && !this.model.isLocked()
    // @ts-expect-error - Backbone View property
    json.downloadGroupCategoryRosterCSVPath = this.model.downloadGroupCategoryRosterCSVPath()
    return json
  }

  // @ts-expect-error - Legacy Backbone typing
  deleteCategory(e) {
    e.preventDefault()

    if (!confirm(I18n.t('delete_confirm', 'Are you sure you want to remove this group set?'))) {
      // @ts-expect-error - Backbone View property
      this.$groupCategoryActions.focus()
      return
    }
    // @ts-expect-error - Backbone View property
    return this.model.destroy({
      success() {
        return $.flashMessage(I18n.t('flash.removed', 'Group set successfully removed.'))
      },
      failure() {
        return $.flashError(
          I18n.t('flash.removeError', 'Unable to remove the group set. Please try again later.'),
        )
      },
    })
  }

  // @ts-expect-error - Legacy Backbone typing
  addGroup(e, open = true) {
    if (e) e.preventDefault()

    ReactDOM.render(
      <GroupModal
        // @ts-expect-error - Backbone View property
        groupCategory={{id: this.model.get('id')}}
        group={{
          // @ts-expect-error - Backbone View property
          role: this.model.get('role'),
          // @ts-expect-error - Backbone View property
          group_limit: this.model.get('group_limit'),
        }}
        label={I18n.t('Add Group')}
        open={open}
        requestMethod="POST"
        onSave={() => this.refreshCollection()}
        onDismiss={() => {
          this.addGroup(null, false)
          // @ts-expect-error - Backbone View property
          this.$addGroupButton.focus()
        }}
      />,
      document.getElementById('group-mount-point'),
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  setProgress(progress) {
    // @ts-expect-error - Backbone View property
    this.model.progressModel.set(progress)
  }

  // @ts-expect-error - Legacy Backbone typing
  importGroups(e) {
    if (e) e.preventDefault()
    const parent = document.getElementById('group-import-modal-mount-point')

    ReactDOM.render(
      <GroupImportModal
        setProgress={this.setProgress.bind(this)}
        // @ts-expect-error - Backbone View property
        groupCategoryId={this.model.id}
        parent={parent}
      />,
      parent,
    )
  }

  editCategory() {
    // @ts-expect-error - Legacy Backbone typing
    if (this.editCategoryView == null) {
      // @ts-expect-error - Legacy Backbone typing
      this.editCategoryView = new GroupCategoryEditView({
        // @ts-expect-error - Backbone View property
        model: this.model,
        // @ts-expect-error - Backbone View property
        trigger: this.$editGroupCategoryLink,
      })
    }
    // @ts-expect-error - Legacy Backbone typing
    return this.editCategoryView.open()
  }

  // @ts-expect-error - Legacy Backbone typing
  cloneCategory(e, open = true) {
    if (e) e.preventDefault()

    ReactDOM.render(
      <GroupCategoryCloneModal
        // implicitly rendered with openedFromCaution: false
        groupCategory={{
          // @ts-expect-error - Backbone View property
          id: this.model.get('id'),
          // @ts-expect-error - Backbone View property
          name: this.model.get('name'),
        }}
        label={I18n.t('Clone Group Set')}
        open={open}
        onDismiss={() => {
          this.cloneCategory(null, false)
          // @ts-expect-error - Backbone View property
          $(`#group-category-${this.model.id}-actions`).focus()
        }}
      />,
      document.getElementById('group-category-clone-mount-point'),
    )
  }

  // @ts-expect-error - Legacy Backbone typing
  messageAllUnassigned(e, open = true) {
    if (e) e.preventDefault()
    const disabler = $.Deferred()
    // @ts-expect-error - Backbone View property
    this.parentView.$el.disableWhileLoading(disabler)
    disabler.done(() => {
      // display the dialog when all data is ready
      // @ts-expect-error - Backbone View property
      const students = this.model
        .unassignedUsers()
        // @ts-expect-error - Legacy Backbone typing
        .map(user => ({id: user.get('id'), short_name: user.get('short_name')}))
      const dialog = () => {
        ReactDOM.render(
          <GroupCategoryMessageAllUnassignedModal
            // @ts-expect-error - Backbone View property
            groupCategory={{name: this.model.get('name')}}
            recipients={students}
            open={open}
            onDismiss={() => {
              this.messageAllUnassigned(null, false)
              // @ts-expect-error - Legacy Backbone typing
              this.$messageAllUnassignedLink.focus()
            }}
          />,
          document.getElementById('group-category-message-all-unassigned-mount-point'),
        )
      }
      return dialog()
    })
    // @ts-expect-error - Backbone View property
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
