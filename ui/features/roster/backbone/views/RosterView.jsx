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
import {QueryProvider} from '@canvas/query'

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
    if(event.hasOwnProperty('userId'))
      $(`#tag-icon-id-${event.userId}`).remove()
  }
  
  reloadUsersTable() {
    this.collection.fetch()
    $(".select-user-checkbox").prop('checked', false).trigger('change')
  }

  fetchOnCreateUsersClose() {
    if (this.addPeopleApp.usersHaveBeenEnrolled()) return this.collection.fetch()
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

  mountUserDiffTagManager(users) {
    const userDTManager = this.$el.find('#userDiffTagManager')[0]
    if (userDTManager && ENV.permissions.can_manage_differentiation_tags) {
      if(!this.userDTManager)
        this.userDTManager = createRoot(userDTManager)
      this.userDTManager.render(
        <QueryProvider>
          <UserDifferentiationTagManager
            courseId={ENV.course.id}
            users={users}
          />
        </QueryProvider>
      )
    }
  }

  HandleUserSelected(event) {
    this.mountUserDiffTagManager(event.selectedUsers)
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
