define [
  'Backbone'
  'jst/accounts/admin_tools/authLoggingItem'
  'i18n!auth_logging'
], (Backbone, template, I18n) ->

  class AuthLoggingItemView extends Backbone.View

    tagName: 'tr'

    className: 'logitem'

    template: template

    toJSON: ->
      json = super
      if json.event_type == "login"
        json.event = I18n.t("login", "LOGIN")
      else if json.event_type == "logout"
        json.event = I18n.t("logout", "LOGOUT")
      else if json.event_type == "corrupted"
        json.event = I18n.t("corrupted", "Details Not Available")
      json
