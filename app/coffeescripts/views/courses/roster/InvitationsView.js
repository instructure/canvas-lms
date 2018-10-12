#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!course_settings'
  'jquery'
  'underscore'
  '../../DialogBaseView'
  'jst/courses/roster/InvitationsView'
  '../../../jquery.rails_flash_notifications'
], (I18n, $, _, DialogBaseView, invitationsViewTemplate) ->

  class InvitationsView extends DialogBaseView

    dialogOptions: ->
      id: 'enrollment_dialog'
      title: I18n.t 're_send_invitation', 'Re-Send Invitation'
      buttons: [
        text: I18n.t 'cancel', 'Cancel'
        click: @cancel
      ,
        text: I18n.t 're_send_invitation', 'Re-Send Invitation'
        'class' : 'btn-primary'
        click: @resend
      ]

    render: ->
      @showDialogButtons()

      data = @model.toJSON()
      data.time = $.datetimeString(_.last(@model.get('enrollments')).updated_at)
      @$el.html invitationsViewTemplate data

      pending = @invitationIsPending()
      admin = @$el.parents(".teacher_enrollments,.ta_enrollments").length > 0
      @$('.student_enrollment_re_send').showIf(pending && !admin)
      @$('.admin_enrollment_re_send').showIf(pending && admin)
      @$('.accepted_enrollment_re_send').showIf(!pending)
      if pending && !admin && data.course && !data.course.available
        @hideDialogButtons()

      this

    invitationIsPending: ()->
      @model.pending(@model.currentRole)

    showDialogButtons: ->
      @$el.parent().next('.ui-dialog-buttonpane').show()

    hideDialogButtons: ->
      @$el.parent().next('.ui-dialog-buttonpane').hide()

    resend: (e) =>
      e.preventDefault()
      @close()
      for e in @model.get('enrollments')
        url = "/confirmations/#{ @model.get('id') }/re_send?enrollment_id=#{ e.id }"
        $.ajaxJSON url
      $.flashMessage I18n.t('flash.invitation', 'Invitation sent.')
