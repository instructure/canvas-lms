define [
  'i18n!registration.success'
  'compiled/fn/preventDefault'
  'jst/registration/registrationSuccessDialog'
], (I18n, preventDefault, template) ->

  $node = $('<div />')

  (channel) ->
    url = "/confirmations/#{channel.user_id}/re_send/#{channel.id}"
    $node.html(template(email: channel.path))

    canResend = true
    $node.find('.re_send_confirmation_link').click preventDefault ->
      return unless canResend
      canResend = false
      $status = $node.find('.re_send_confirmation_status')
      $status.text(I18n.t("resending", "Re-sending confirmation email..."))
      $.ajaxJSON url, 'POST', {}, (data) ->
        $status.text(I18n.t("done_resending", "Done! Message delivery may take a few minutes."))
      , (data) ->
        $status.text(I18n.t("failed_resending", "Request failed. Try again."))
        canResend = true

    $node.find('.ok_close').click ->
      $node.dialog('close')

    $node.dialog
      resizable: false
      title: I18n.t('title', "You're almost there...")
      width: 550
