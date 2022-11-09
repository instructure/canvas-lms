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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@canvas/backbone'
import template from '../../jst/resendInvitations.handlebars'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('ResendInvitationsView')

export default class ResendInvitationsView extends View {
  static initClass() {
    this.optionProperty('canResend')

    this.optionProperty('resendInvitationsUrl')

    this.prototype.events = {'click .resend-pending-invitations': 'resendPendingInvitations'}

    this.prototype.template = template
  }

  toJSON() {
    return {...this.model.toJSON(), ...this}
  }

  attach() {
    return this.model.on('change:pendingInvitationsCount', this.render, this)
  }

  resendPendingInvitations(_e) {
    this.sending = true
    this.render()
    const xhr = $.ajaxJSON(
      this.resendInvitationsUrl,
      'POST',
      {},
      () => $.flashMessage(I18n.t('invitations_re_sent', 'Invitations sent successfully')),
      () =>
        $.flashError(
          I18n.t('error_sending_invitations', 'Error sending invitation. Please try again.')
        )
    )
    return $.when(xhr).always(() => (this.sending = false), this.render.bind(this))
  }
}
ResendInvitationsView.initClass()
