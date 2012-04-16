define [
  'i18n!course_settings'
  'jquery'
  'underscore'
  'compiled/views/DialogBaseView'
  'jst/courses/settings/InvitationsView'
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
      data.time = $.parseFromISO(_.last(@model.get('enrollments')).updated_at).datetime_formatted
      data.course = ENV.CONTEXTS['courses'][ENV.COURSE_ID]
      @$el.html invitationsViewTemplate data

      pending = @model.pending()
      admin = @$el.parents(".teacher_enrollments,.ta_enrollments").length > 0
      @$('.student_enrollment_re_send').showIf(pending && !admin)
      @$('.admin_enrollment_re_send').showIf(pending && admin)
      @$('.accepted_enrollment_re_send').showIf(!pending)
      if pending && !admin && !data.course.available
        @hideDialogButtons()

      this

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

    removeSection: (e) ->
      $token = $(e.currentTarget).closest('li')
      if $token.closest('ul').children().length > 1
        $token.remove()