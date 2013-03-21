define [
  'i18n!conversations'
  'Backbone'
  'underscore'
  'jquery'
], (I18n,{Model},_,$) ->

  class Conversation extends Model

    # This new class is here instead of reusing
    # coffeescripts/models/conversations/Conversation.coffee in order to
    # take advantage of the API.
    #
    # For a full list of supported attributes, see the Conversation API
    # documentation.

    url: '/api/v1/conversations'

    BLANK_BODY_ERR = I18n.t 'cannot_be_empty', 'Message cannot be blank'
    NO_RECIPIENTS_ERR = I18n.t('no_recipients_choose_another_group',
      'No recipients are in this group. Please choose another group.')

    validate: (attrs,options) ->
      errors = {}
      if !attrs.body or !$.trim(attrs.body.toString())
        errors.body = [ message: BLANK_BODY_ERR ]
      if !attrs.recipients || !attrs.recipients.length
        errors.recipients = [ message: NO_RECIPIENTS_ERR ]
      if _.keys(errors).length
        errors
      else
        undefined

