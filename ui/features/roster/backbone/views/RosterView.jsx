//
// Copyright (C) 2012 - present Instructure, Inc.
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
import Backbone from '@canvas/backbone'
import template from '../../jst/index.handlebars'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import AddPeopleApp from '@canvas/add-people'
import React from 'react'
import {createRoot} from 'react-dom/client'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {initializeTopNavPortalWithDefaults} from '@canvas/top-navigation/react/TopNavPortalWithDefaults'
import UserDifferentiationTagManager from '@canvas/differentiation-tags/react/UserDifferentiationTagManager/UserDifferentiationTagManager'
import MessageBus from '@canvas/util/MessageBus'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {union} from 'lodash'

const I18n = createI18nScope('RosterView')

export default class RosterView extends Backbone.View {
  static initClass() {
    this.mixin(ValidatedMixin)

    this.child('usersView', '[data-view=users]')

    this.child('inputFilterView', '[data-view=inputFilter]')

    this.child('roleSelectView', '[data-view=roleSelect]')

    this.child('resendInvitationsView', '[data-view=resendInvitations]')

    this.child('rosterTabsView', '[data-view=rosterTabs]')

    this.optionProperty('roles')

    this.optionProperty('permissions')

    this.optionProperty('course')

    this.prototype.template = template

    this.prototype.els = {
      '#addUsers': '$addUsersButton',
      '#createUsersModalHolder': '$createUsersModalHolder',
    }
    this.prototype.events = {
      'change .select-all-users-checkbox': 'handleSelectAllCheckboxChange',
    }
    const handleBreadCrumbSetter = ({getCrumbs, setCrumbs}) => {
      const crumbs = getCrumbs()
      crumbs.push({name: I18n.t('People'), url: ''})
      setCrumbs(crumbs)
    }
    initializeTopNavPortalWithDefaults({
      getBreadCrumbSetter: handleBreadCrumbSetter,
      useStudentView: true,
    })
  }

  constructor(options) {
    super(options)
    this.root = null
  }

  // When the master checkbox changes, either select everything or clear all.
  // Also resets the deselected list if we uncheck the master.
  handleSelectAllCheckboxChange(e) {
    const isChecked = e.currentTarget.checked
    this.collection.masterSelected = isChecked

    this.collection.lastCheckedIndex = null

    if (isChecked) {
      // Clear the de-selected list
      this.collection.deselectedUserIds = []

      // Collect all loaded user IDs that have a checkbox (students)
      const allUserIds = this.collection
        .filter(model => model.hasEnrollmentType('StudentEnrollment'))
        .map(m => m.id)

      this.collection.selectedUserIds = union(this.collection.selectedUserIds, allUserIds)
    } else {
      this.collection.selectedUserIds = []
      this.collection.deselectedUserIds = []
    }

    this.$('.select-user-checkbox').prop('checked', isChecked)
    this.updateSelectAllState()

    MessageBus.trigger('userSelectionChanged', {
      selectedUsers: this.collection.selectedUserIds,
      deselectedUserIds: this.collection.deselectedUserIds,
      masterSelected: this.collection.masterSelected,
    })
  }

  handleCollectionSync() {
    // If the user has “select all” turned on, automatically select newly loaded user IDs
    // except those specifically de-selected.
    if (this.collection.masterSelected) {
      let allUserIds = this.collection
        .filter(model => model.hasEnrollmentType('StudentEnrollment'))
        .map(m => m.id)

      // Exclude any that the user has specifically de-selected
      allUserIds = allUserIds.filter(id => !this.collection.deselectedUserIds.includes(id))

      this.collection.selectedUserIds = union(this.collection.selectedUserIds, allUserIds)

      this.$('.select-user-checkbox').prop('checked', true)
    }
    this.updateSelectAllState()
  }

  updateSelectAllState() {
    const $masterCheckbox = this.$('.select-all-users-checkbox')
    if (!$masterCheckbox.length) return

    const totalStudentCount = this.collection.filter(m =>
      m.hasEnrollmentType('StudentEnrollment'),
    ).length

    const selectedCount = this.collection.selectedUserIds.length

    if (selectedCount === 0) {
      $masterCheckbox.prop('indeterminate', false)
      $masterCheckbox.prop('checked', false)
    } else if (selectedCount === totalStudentCount) {
      $masterCheckbox.prop('indeterminate', false)
      $masterCheckbox.prop('checked', true)
      this.collection.masterSelected = true
    } else {
      $masterCheckbox.prop('checked', false)
      $masterCheckbox.prop('indeterminate', true)
    }
  }

  afterRender() {
    const container = this.$el.find('#search_input_container')[0]
    if (container) {
      this.root = createRoot(container)
      this.root.render(
        <TextInput
          onChange={e => {
            // Sends events to hidden input to utilize backbone
            const hiddenInput = $('[data-view=inputFilter]')
            hiddenInput[0].value = e.target?.value
            hiddenInput.keyup()
          }}
          display="inline-block"
          type="text"
          placeholder={I18n.t('Search people')}
          renderLabel={
            <ScreenReaderContent>
              {I18n.t(
                'Search people. As you type in this field, the list of people will be automatically filtered to only include those whose names match your input.',
              )}
            </ScreenReaderContent>
          }
          renderBeforeInput={() => <IconSearchLine />}
        />,
      )
    }

    this.$addUsersButton.on('click', this.showCreateUsersModal.bind(this))
    this.mountUserDiffTagManager([])
    const canReadSIS = 'permissions' in ENV ? !!ENV.permissions.read_sis : true
    const canAddUser = role => role.addable_by_user

    return (this.addPeopleApp = new AddPeopleApp(this.$createUsersModalHolder[0], {
      courseId: (ENV.course && ENV.course.id) || 0,
      defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
      roles: (ENV.ALL_ROLES || []).filter(canAddUser),
      sections: ENV.SECTIONS || [],
      onClose: () => this.fetchOnCreateUsersClose(),
      inviteUsersURL: ENV.INVITE_USERS_URL,
      canReadSIS,
    }))
  }

  attach() {
    MessageBus.on('userSelectionChanged', this.HandleUserSelected, this)
    MessageBus.on('removeUserTagIcon', this.removeTagIcon, this)
    MessageBus.on('reloadUsersTable', this.reloadUsersTable, this)
    return this.collection.on('setParam deleteParam', this.fetch, this)
  }

  removeTagIcon(event) {
    if (event.hasOwnProperty('userId')) {
      $(`#tag-icon-id-${event.userId}`).remove()
    }
  }

  reloadUsersTable() {
    this.collection.masterSelected = false
    this.collection.deselectedUserIds = []
    this.collection.selectedUserIds = []

    this.collection.fetch()
    $('.select-user-checkbox').prop('checked', false).trigger('change')
  }

  fetchOnCreateUsersClose() {
    if (this.addPeopleApp.usersHaveBeenEnrolled()) {
      return this.collection.fetch()
    }
  }

  fetch() {
    if (this.lastRequest != null) {
      this.lastRequest.abort()
    }
    return (this.lastRequest = this.collection.fetch().fail(this.onFail.bind(this)))
  }

  course_id() {
    return ENV.context_asset_string.split('_')[1]
  }

  canAddCategories() {
    return ENV.canManageCourse
  }

  isHorizonCourse() {
    return ENV.horizon_course
  }

  toJSON() {
    return this
  }

  onFail(xhr) {
    if (xhr.statusText === 'abort') return
    const parsed = JSON.parse(xhr.responseText)
    const message =
      __guard__(parsed != null ? parsed.errors : undefined, x => x[0].message) ===
      '3 or more characters is required'
        ? I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
        : I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
    return this.showErrors({search_term: [{message}]})
  }

  showCreateUsersModal() {
    return this.addPeopleApp.open()
  }

  mountUserDiffTagManager(users, exceptions, allInCourse) {
    const userDTManager = this.$el.find('#userDiffTagManager')[0]
    if (
      userDTManager &&
      ENV.permissions.can_manage_differentiation_tags &&
      ENV.permissions.allow_assign_to_differentiation_tags
    ) {
      if (!this.userDTManager) {
        this.userDTManager = createRoot(userDTManager)
      }
      this.userDTManager.render(
        <QueryClientProvider client={queryClient}>
          <UserDifferentiationTagManager
            courseId={ENV.course.id}
            users={users}
            allInCourse={allInCourse}
            userExceptions={exceptions}
          />
        </QueryClientProvider>,
      )
    }
  }

  HandleUserSelected(event) {
    this.updateSelectAllState()
    this.mountUserDiffTagManager(event.selectedUsers, event.deselectedUserIds, event.masterSelected)
  }

  remove() {
    if (this.root) {
      this.root.unmount()
      this.root = null
    }
    if (this.differentiationTagTrayRoot) {
      this.differentiationTagTrayRoot.unmount()
      this.differentiationTagTrayRoot = null
    }
    if (this.userDTManager) {
      this.userDTManager.unmount()
      this.userDTManager = null
    }
    super.remove()
  }
}
RosterView.initClass()
function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
