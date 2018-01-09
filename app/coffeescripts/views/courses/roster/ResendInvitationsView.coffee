#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'i18n!roster'
  'Backbone'
  'jst/courses/roster/resendInvitations'
  'jquery.ajaxJSON'
  '../../../jquery.rails_flash_notifications'
], ($, _, I18n, {View}, template) ->

  class ResendInvitationsView extends View
    @optionProperty 'canResend'

    @optionProperty 'resendInvitationsUrl'

    events:
      'click .resend-pending-invitations': 'resendPendingInvitations'

    template: template

    toJSON: ->
      _.extend {}, @model.toJSON(), this

    attach: ->
      @model.on 'change:pendingInvitationsCount', @render, this

    resendPendingInvitations: (e) ->
      @sending = true
      @render()
      xhr = $.ajaxJSON(@resendInvitationsUrl, 'POST', {}, ->
        $.flashMessage(I18n.t('invitations_re_sent', "Invitations sent successfully"))
      , ->
        $.flashError(I18n.t('error_sending_invitations', "Error sending invitation. Please try again."))
      )
      $.when(xhr).always (=> @sending = false), @render

