define [
  'jquery'
  'jst/profiles/notifications/privacyNotice'
  'compiled/jquery/fixDialogButtons'
], ($, privacyNoticeTpl) ->

  ->
    return if ENV.READ_PRIVACY_INFO or !ENV.ACCOUNT_PRIVACY_NOTICE
    $privacyNotice = $(privacyNoticeTpl())
    $privacyNotice.appendTo('body').dialog(
      close: (event, ui) -> $.post('/profile', _method: 'put', privacy_notice: 1)
      title: $privacyNotice.data('title')
    ).fixDialogButtons()
