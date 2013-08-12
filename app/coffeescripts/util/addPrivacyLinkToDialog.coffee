define [
  'i18n!site'
], (I18n) ->

  addPrivacyLinkToDialog = ($dialog) ->
    return unless ENV.ACCOUNT.privacy_policy_url
    $privacy = $('<a>', href: ENV.ACCOUNT.privacy_policy_url, style: "padding-left: 1em; line-height: 3em", 'class': 'privacy_policy_link', target: "_blank")
    $buttonPane = $dialog.closest('.ui-dialog').find('.ui-dialog-buttonpane')
    if !$buttonPane.find('.privacy_policy_link').length
      $privacy.text I18n.t('view_privacy_policy', 'View Privacy Policy')
      $buttonPane.append($privacy)

