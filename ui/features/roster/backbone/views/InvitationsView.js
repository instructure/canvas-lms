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

import {useScope as useI18nScope} from '@canvas/i18n'

import $ from 'jquery'
import {last} from 'lodash'
import DialogBaseView from '@canvas/dialog-base-view'
import invitationsViewTemplate from '../../jst/InvitationsView.handlebars'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('course_settings')

export default class InvitationsView extends DialogBaseView {
  dialogOptions() {
    return {
      id: 'enrollment_dialog',
      title: I18n.t('re_send_invitation', 'Resend Invitation'),
      buttons: [
        {
          text: I18n.t('cancel', 'Cancel'),
          click: this.cancel,
        },
        {
          text: I18n.t('re_send_invitation', 'Resend Invitation'),
          class: 'btn-primary',
          click: this.resend.bind(this),
        },
      ],
      modal: true,
      zIndex: 1000,
    }
  }

  render() {
    this.showDialogButtons()

    const data = this.model.toJSON()
    data.time = $.datetimeString(last(this.model.get('enrollments')).updated_at)
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
    return this.$el.parent().next('.ui-dialog-buttonpane').show()
  }

  hideDialogButtons() {
    return this.$el.parent().next('.ui-dialog-buttonpane').hide()
  }

  sendInvitation(e) {
    const url = `/confirmations/${this.model.get('id')}/re_send?enrollment_id=${e.id}`
    $.ajaxJSON(url)
  }

  resend(e) {
    e.preventDefault()
    this.close()
    for (e of this.model.get('enrollments')) {
      if (ENV.FEATURES.granular_permissions_manage_users) {
        if (ENV.permissions.active_granular_enrollment_permissions.includes(e.type)) {
          this.sendInvitation(e)
        }
      } else {
        this.sendInvitation(e)
      }
    }
    return $.flashMessage(I18n.t('flash.invitation', 'Invitation sent.'))
  }
}
