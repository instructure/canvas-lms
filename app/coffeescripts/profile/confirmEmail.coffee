define [
  'jquery',
  'i18n!profile'
  'compiled/fn/preventDefault',
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, preventDefault) ->
  $ ->
    resending = false

    $('.re_send_confirmation_link').click preventDefault ->
      $this = $(this)
      text = $this.text()

      return if resending
      resending = true
      $this.text I18n.t('resending', 'resending...')

      $.ajaxJSON $this.attr('href'), 'POST', {}, (data) ->
        resending = false
        $this.text text
        $.flashMessage I18n.t("done_resending", "Done! Message delivery may take a few minutes.")
      , (data) ->
        resending = false
        $this.text text
        $.flashError I18n.t("failed_resending", "Request failed. Try again.")
        
