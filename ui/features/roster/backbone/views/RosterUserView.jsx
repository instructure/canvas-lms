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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, some, every, find, filter, reject, isEmpty} from 'lodash'
import Backbone from '@canvas/backbone'
import template from '../../jst/rosterUser.handlebars'
import EditSectionsView from './EditSectionsView'
import EditRolesView from './EditRolesView'
import InvitationsView from './InvitationsView'
import LinkToStudentsView from './LinkToStudentsView'
import React from 'react'
import ReactDOM from 'react-dom'
import {Avatar} from '@instructure/ui-avatar'
import {nanoid} from 'nanoid'
import 'jquery-kyle-menu'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('RosterUserView')

let editSectionsDialog = null
let editRolesDialog = null
let linkToStudentsDialog = null
let invitationDialog = null

export default class RosterUserView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'tr'

    this.prototype.className = 'rosterUser al-hover-container'

    this.prototype.template = template

    this.prototype.events = {
      'click .admin-links [data-event]': 'handleMenuEvent',
      'focus *': 'focus',
      'blur *': 'blur',
    }
  }

  attach() {
    return this.model.on('change', this.render, this)
  }

  initialize(options) {
    options.model.attributes.avatarId = `user-avatar-people-page-${nanoid()}`
    super.initialize(...arguments)
    // assumes this model only has enrollments for 1 role
    this.model.currentRole = __guard__(this.model.get('enrollments')[0], x => x.role)

    this.$el.attr('id', `user_${options.model.get('id')}`)
    return Array.from(this.model.get('enrollments')).map(e => this.$el.addClass(e.type))
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    this.permissionsJSON(json)
    this.observerJSON(json)
    this.contextCardJSON(json)
    return json
  }

  contextCardJSON(json) {
    let enrollment
    if ((enrollment = find(json.enrollments, e => e.type === 'StudentEnrollment'))) {
      return (json.course_id = enrollment.course_id)
    }
  }

  permissionsJSON(json) {
    json.url = `${ENV.COURSE_ROOT_URL}/users/${this.model.get('id')}`
    json.faculyJournalUrl = `/users/${this.model.get('id')}/user_notes`
    json.isObserver = this.model.hasEnrollmentType('ObserverEnrollment')
    json.isPending = this.model.pending(this.model.currentRole)
    json.isInactive = this.model.inactive()
    if (!json.isInactive) {
      json.enrollments = reject(json.enrollments, en => en.enrollment_state === 'inactive') // if not _completely_ inactive, treat the inactive enrollments as deleted
    }
    json.canRemoveUsers = every(this.model.get('enrollments'), e => e.can_be_removed)
    json.canResendInvitation =
      !json.isInactive && (ENV.FEATURES.granular_permissions_manage_users
        ? some(this.model.get('enrollments'), en =>
            ENV.permissions.active_granular_enrollment_permissions.includes(en.type)
          )
        : true)

    if (json.canRemoveUsers && !ENV.course.concluded) {
      json.canEditRoles = !some(
        this.model.get('enrollments'),
        e => e.type === 'ObserverEnrollment' && e.associated_user_id
      )
    }

    json.canEditSections = !json.isInactive && !isEmpty(this.model.sectionEditableEnrollments())
    json.canLinkStudents = json.isObserver && !ENV.course.concluded
    json.canViewLoginIdColumn = ENV.permissions.view_user_logins
    json.canViewSisIdColumn = ENV.permissions.read_sis
    json.canManageUserNotes = ENV.permissions.manage_user_notes

    const candoAdminActions =
      ENV.permissions.can_allow_course_admin_actions || ENV.permissions.manage_admin_users
    json.canManage = some(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], et =>
      this.model.hasEnrollmentType(et)
    )
      ? candoAdminActions
      : this.model.hasEnrollmentType('ObserverEnrollment')
      ? candoAdminActions || ENV.permissions.manage_students
      : ENV.permissions.manage_students
    json.customLinks = this.model.get('custom_links')

    if (json.canViewLoginIdColumn) {
      json.canViewLoginId = true
    }

    if (json.canViewSisIdColumn) {
      json.canViewSisId = true
      json.sis_id = json.sis_user_id
    }
    json.hideSectionsOnCourseUsersPage = ENV.course.hideSectionsOnCourseUsersPage
    return json
  }

  observerJSON(json) {
    if (json.isObserver) {
      let user
      const observerEnrollments = filter(json.enrollments, en => en.type === 'ObserverEnrollment')
      json.enrollments = reject(json.enrollments, en => en.type === 'ObserverEnrollment')

      json.sections = map(json.enrollments, en => ENV.CONTEXTS.sections[en.course_section_id])

      const users = {}
      if (
        observerEnrollments.length >= 1 &&
        every(observerEnrollments, enrollment => !enrollment.observed_user)
      ) {
        users[''] = {name: I18n.t('nobody', 'nobody')}
      } else {
        for (const en of Array.from(observerEnrollments)) {
          if (!en.observed_user) {
            continue
          }
          user = en.observed_user
          if (!users[user.id]) {
            users[user.id] = user
          }
        }
      }

      return (() => {
        const result = []
        for (const id in users) {
          user = users[id]
          const ob = {
            role: I18n.t('observing_user', 'Observing: %{user_name}', {user_name: user.name}),
          }
          result.push(json.enrollments.push(ob))
        }
        return result
      })()
    }
  }

  resendInvitation() {
    if (!invitationDialog) {
      invitationDialog = new InvitationsView()
    }
    invitationDialog.model = this.model
    return invitationDialog.render().show()
  }

  editSections() {
    if (!editSectionsDialog) {
      editSectionsDialog = new EditSectionsView()
    }
    editSectionsDialog.model = this.model
    return editSectionsDialog.render().show()
  }

  editRoles() {
    if (!editRolesDialog) {
      editRolesDialog = new EditRolesView()
    }
    editRolesDialog.model = this.model
    return editRolesDialog.render().show()
  }

  linkToStudents() {
    if (!linkToStudentsDialog) {
      linkToStudentsDialog = new LinkToStudentsView()
    }
    linkToStudentsDialog.model = this.model
    return linkToStudentsDialog.render().show()
  }

  deactivateUser() {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        I18n.t(
          'Are you sure you want to deactivate this user? They will be unable to participate in the course while inactive.'
        )
      )
    ) {
      return
    }
    const deferreds = []
    for (const en of Array.from(this.model.get('enrollments'))) {
      if (en.enrollment_state !== 'inactive') {
        const url = `/api/v1/courses/${ENV.course.id}/enrollments/${en.id}?task=deactivate`
        en.enrollment_state = 'inactive'
        deferreds.push($.ajaxJSON(url, 'DELETE'))
      }
    }

    return $('.roster-tab').disableWhileLoading(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.render()
          return $.flashMessage(I18n.t('User successfully deactivated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t('Something went wrong while deactivating the user. Please try again later.')
          )
        )
    )
  }

  reactivateUser() {
    const deferreds = []
    for (const en of Array.from(this.model.get('enrollments'))) {
      const url = `/api/v1/courses/${ENV.course.id}/enrollments/${en.id}/reactivate`
      en.enrollment_state = 'active'
      deferreds.push($.ajaxJSON(url, 'PUT'))
    }

    return $('.roster-tab').disableWhileLoading(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.render()
          return $.flashMessage(I18n.t('User successfully re-activated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t('Something went wrong re-activating the user. Please try again later.')
          )
        )
    )
  }

  removeFromCourse(_e) {
    // eslint-disable-next-line no-alert
    if (!window.confirm(I18n.t('Are you sure you want to remove this user?'))) {
      return
    }
    this.$el.hide()
    const success = () => {
      // TODO: change the count on the search roles drop down
      $.flashMessage(I18n.t('User successfully removed.'))
      const $previousRow = this.$el.prev(':visible')
      const $focusElement = $previousRow.length
        ? $previousRow.find('.al-trigger')
        : // For some reason, VO + Safari sends the virtual cursor to the window
          // instead of to this element, this has the side effect of making the
          // flash message not read either in this case :(
          // Looking at the Tech Preview version of Safari, this isn't an issue
          // so it should start working once new Safari is released.
          $('#addUsers')
      return $focusElement.focus()
    }

    const failure = () => {
      this.$el.show()
      return $.flashError(
        I18n.t('flash.removeError', 'Unable to remove the user. Please try again later.')
      )
    }
    const deferreds = map(this.model.get('enrollments'), e =>
      $.ajaxJSON(`${ENV.COURSE_ROOT_URL}/unenroll/${e.id}`, 'DELETE')
    )
    return $.when(...Array.from(deferreds || [])).then(success, failure)
  }

  handleMenuEvent(e) {
    this.blur()
    e.preventDefault()
    const method = $(e.currentTarget).data('event')
    return this[method].call(this, e)
  }

  focus() {
    return this.$el.addClass('al-hover-container-active table-hover-row')
  }

  blur() {
    return this.$el.removeClass('al-hover-container-active table-hover-row')
  }

  afterRender() {
    ReactDOM.render(
      <a href={`users/${this.model.id}`}>
        <Avatar
          name={this.model.attributes.name}
          src={this.model.attributes.avatar_url}
          size="small"
          alt={this.model.attributes.name}
        />
        <span className="screenreader-only">{this.model.attributes.name}</span>
      </a>,
      this.$el.find(`#${this.model.attributes.avatarId}`)[0]
    )
  }
}
RosterUserView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
