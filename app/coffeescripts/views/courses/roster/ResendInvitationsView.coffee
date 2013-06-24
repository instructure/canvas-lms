define [
  'jquery'
  'underscore'
  'i18n!roster'
  'Backbone'
  'jst/courses/roster/resendInvitations'
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
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

