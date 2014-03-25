define [
  'i18n!dashboard'
  'jquery'
  'compiled/views/QuickStartBar/BaseItemView'
  'compiled/models/Message'
  'jst/quickStartBar/message'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, BaseItemView, Message, template) ->

  class MessageView extends BaseItemView

    template: template

    contextSearchOptions:
      fakeInputWidth: '100%'
      contexts: ENV.CONTEXTS
      placeholder: "Type the name of the person to send this to..."
      selector:
        noExpand: true
        browser: false

    initialize: ->
      super
      @model or= new Message

    save: (json) ->
      @model.save(json).done ->
        $.flashMessage I18n.t 'message_sent', 'Message Sent'

    @type:  'message'
    @title: -> super 'message', 'Message'
