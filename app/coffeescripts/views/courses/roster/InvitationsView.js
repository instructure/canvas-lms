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

import I18n from 'i18n!course_settings'

import $ from 'jquery'
import _ from 'underscore'
import DialogBaseView from '../../DialogBaseView'
import invitationsViewTemplate from 'jst/courses/roster/InvitationsView'
import '../../../jquery.rails_flash_notifications'

export default class InvitationsView extends DialogBaseView {
  dialogOptions() {
    return {
      id: 'enrollment_dialog',
      title: I18n.t('re_send_invitation', 'Resend Invitation'),
      buttons: [
        {
          text: I18n.t('cancel', 'Cancel'),
          click: this.cancel
        },
        {
          text: I18n.t('re_send_invitation', 'Resend Invitation'),
          class: 'btn-primary',
          click: this.resend.bind(this)
        }
      ]
    }
  }

  render() {
    this.showDialogButtons()

    const data = this.model.toJSON()
    data.time = $.datetimeString(_.last(this.model.get('enrollments')).updated_at)
    this.$el.html(invitationsViewTemplate(data))

    const pending = this.invitationIsPending()
    const admin = this.$el.parents('.teacher_enrollments,.ta_enrollments').length > 0
    this.$('.student_enrollment_re_send').showIf(pending && !admin)
    this.$('.admin_enrollment_re_send').showIf(pending && admin)
    this.$('.accepted_enrollment_re_send').showIf(!pending)
    if (pending && !admin && data.course && !data.course.available) {
      this.hideDialogButtons()
    }

    return this
  }

  invitationIsPending() {
    return this.model.pending(this.model.currentRole)
  }

  showDialogButtons() {
    return this.$el
      .parent()
      .next('.ui-dialog-buttonpane')
      .show()
  }

  hideDialogButtons() {
    return this.$el
      .parent()
      .next('.ui-dialog-buttonpane')
      .hide()
  }

  resend(e) {
    e.preventDefault()
    this.close()
    for (e of this.model.get('enrollments')) {
      const url = `/confirmations/${this.model.get('id')}/re_send?enrollment_id=${e.id}`
      $.ajaxJSON(url)
    }
    return $.flashMessage(I18n.t('flash.invitation', 'Invitation sent.'))
  }
}
