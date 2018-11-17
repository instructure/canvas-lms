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

import I18n from 'i18n!roster'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import template from 'jst/courses/roster/rosterUser'
import EditSectionsView from './EditSectionsView'
import EditRolesView from './EditRolesView'
import InvitationsView from './InvitationsView'
import LinkToStudentsView from './LinkToStudentsView'
import '../../../jquery.kylemenu'
import 'jquery.disableWhileLoading'

let editSectionsDialog = null
let editRolesDialog = null
let linkToStudentsDialog = null
let invitationDialog = null

export default class RosterUserView extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.handleMenuEvent = this.handleMenuEvent.bind(this)
    this.focus = this.focus.bind(this)
    this.blur = this.blur.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.tagName = 'tr'

    this.prototype.className = 'rosterUser al-hover-container'

    this.prototype.template = template

    this.prototype.events = {
      'click .admin-links [data-event]': 'handleMenuEvent',
      'focus *': 'focus',
      'blur *': 'blur'
    }
  }

  attach() {
    return this.model.on('change', this.render, this)
  }

  initialize(options) {
    super.initialize(...arguments)
    // assumes this model only has enrollments for 1 role
    this.model.currentRole = __guard__(this.model.get('enrollments')[0], x => x.role)

    this.$el.attr('id', `user_${options.model.get('id')}`)
    return Array.from(this.model.get('enrollments')).map(e => this.$el.addClass(e.role))
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
    if ((enrollment = _.find(json.enrollments, e => e.type === 'StudentEnrollment'))) {
      return (json.course_id = enrollment.course_id)
    }
  }

  permissionsJSON(json) {
    json.url = `${ENV.COURSE_ROOT_URL}/users/${this.model.get('id')}`
    json.isObserver = this.model.hasEnrollmentType('ObserverEnrollment')
    json.isPending = this.model.pending(this.model.currentRole)
    json.isInactive = this.model.inactive()
    if (!json.isInactive) {
      json.enrollments = _.reject(json.enrollments, en => en.enrollment_state === 'inactive') // if not _completely_ inactive, treat the inactive enrollments as deleted
    }

    json.canRemoveUsers = _.all(this.model.get('enrollments'), e => e.can_be_removed)
    json.canResendInvitation = !json.isInactive

    if (json.canRemoveUsers && !ENV.course.concluded) {
      json.canEditRoles = !_.any(
        this.model.get('enrollments'),
        e => e.type === 'ObserverEnrollment' && e.associated_user_id
      )
    }

    json.canEditSections = !json.isInactive && !_.isEmpty(this.model.sectionEditableEnrollments())
    json.canLinkStudents = json.isObserver && !ENV.course.concluded
    json.canViewLoginIdColumn =
      ENV.permissions.manage_admin_users || ENV.permissions.manage_students
    json.canViewSisIdColumn = ENV.permissions.read_sis
    json.canManage = _.any(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], et =>
      this.model.hasEnrollmentType(et)
    )
      ? ENV.permissions.manage_admin_users
      : this.model.hasEnrollmentType('ObserverEnrollment')
        ? ENV.permissions.manage_admin_users || ENV.permissions.manage_students
        : ENV.permissions.manage_students
    json.customLinks = this.model.get('custom_links')

    if (json.canViewLoginIdColumn) {
      json.canViewLoginId = true
      json.login_id = json.login_id
    }

    if (json.canViewSisIdColumn) {
      json.canViewSisId = true
      return (json.sis_id = json.sis_user_id)
    }
  }

  observerJSON(json) {
    if (json.isObserver) {
      let user
      const observerEnrollments = _.filter(json.enrollments, en => en.type === 'ObserverEnrollment')
      json.enrollments = _.reject(json.enrollments, en => en.type === 'ObserverEnrollment')

      json.sections = _.map(json.enrollments, en => ENV.CONTEXTS['sections'][en.course_section_id])

      const users = {}
      if (
        observerEnrollments.length >= 1 &&
        _.all(observerEnrollments, enrollment => !enrollment.observed_user)
      ) {
        users[''] = {name: I18n.t('nobody', 'nobody')}
      } else {
        for (let en of Array.from(observerEnrollments)) {
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
        for (let id in users) {
          user = users[id]
          const ob = {
            role: I18n.t('observing_user', 'Observing: %{user_name}', {user_name: user.name})
          }
          result.push(json.enrollments.push(ob))
        }
        return result
      })()
    }
  }

  resendInvitation(e) {
    if (!invitationDialog) {
      invitationDialog = new InvitationsView()
    }
    invitationDialog.model = this.model
    return invitationDialog.render().show()
  }

  editSections(e) {
    if (!editSectionsDialog) {
      editSectionsDialog = new EditSectionsView()
    }
    editSectionsDialog.model = this.model
    return editSectionsDialog.render().show()
  }

  editRoles(e) {
    if (!editRolesDialog) {
      editRolesDialog = new EditRolesView()
    }
    editRolesDialog.model = this.model
    return editRolesDialog.render().show()
  }

  linkToStudents(e) {
    if (!linkToStudentsDialog) {
      linkToStudentsDialog = new LinkToStudentsView()
    }
    linkToStudentsDialog.model = this.model
    return linkToStudentsDialog.render().show()
  }

  deactivateUser() {
    if (
      !confirm(
        I18n.t(
          'Are you sure you want to deactivate this user? They will be unable to participate in the course while inactive.'
        )
      )
    ) {
      return
    }
    const deferreds = []
    for (let en of Array.from(this.model.get('enrollments'))) {
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
    for (let en of Array.from(this.model.get('enrollments'))) {
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

  removeFromCourse(e) {
    if (!confirm(I18n.t('Are you sure you want to remove this user?'))) {
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
    const deferreds = _.map(this.model.get('enrollments'), e =>
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
}
RosterUserView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
