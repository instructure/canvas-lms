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

import I18n from 'i18n!roster'
import $ from 'jquery'
import Backbone from 'Backbone'
import template from 'jst/courses/roster/index'
import ValidatedMixin from '../../ValidatedMixin'
import AddPeopleApp from 'jsx/add_people/add_people_app'

export default class RosterView extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.fetchOnCreateUsersClose = this.fetchOnCreateUsersClose.bind(this)
    this.fetch = this.fetch.bind(this)
    this.onFail = this.onFail.bind(this)
    super(...args)
  }

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
      '#createUsersModalHolder': '$createUsersModalHolder'
    }
  }

  afterRender() {
    this.$addUsersButton.on('click', this.showCreateUsersModal.bind(this))

    const canReadSIS = 'permissions' in ENV ? !!ENV.permissions.read_sis : true

    return (this.addPeopleApp = new AddPeopleApp(this.$createUsersModalHolder[0], {
      courseId: (ENV.course && ENV.course.id) || 0,
      defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
      roles: (ENV.ALL_ROLES || []).filter(role => role.manageable_by_user),
      sections: ENV.SECTIONS || [],
      onClose: this.fetchOnCreateUsersClose,
      inviteUsersURL: ENV.INVITE_USERS_URL,
      canReadSIS
    }))
  }

  attach() {
    return this.collection.on('setParam deleteParam', this.fetch)
  }

  fetchOnCreateUsersClose() {
    if (this.addPeopleApp.usersHaveBeenEnrolled()) return this.collection.fetch()
  }

  fetch() {
    if (this.lastRequest != null) {
      this.lastRequest.abort()
    }
    return (this.lastRequest = this.collection.fetch().fail(this.onFail))
  }

  course_id() {
    return ENV.context_asset_string.split('_')[1]
  }

  canAddCategories() {
    return ENV.canManageCourse
  }

  toJSON() {
    return this
  }

  onFail(xhr) {
    if (xhr.statusText === 'abort') return
    const parsed = $.parseJSON(xhr.responseText)
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
}
RosterView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
