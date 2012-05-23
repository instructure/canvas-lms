define [
  'i18n!dashboard'
  'Backbone'
  'compiled/home/models/quickStartBar/Message'
  'jst/quickStartBar/message'
  'jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, {View}, Message, template) ->

  class MessageView extends View

    initialize: ->
      @model or= new Message

    render: ->
      html = template @model.toJSON
      @$el.html html
      @filter()

    onFormSubmit: (json) ->
      dfd = @model.save json,
        success: =>
          $.flashMessage I18n.t 'message_sent', 'Message Sent'
          @parentView.onSaveSuccess()
        fail: @onSaveFail

      @$('form').disableWhileLoading dfd

    onFail: ->
      # TODO

    filter: ->
      @$('.recipients').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: "Type the name of the person to send this to..."
        selector:
          preparer: (postData, data, parent) ->
            for row in data
              row.noExpand = true
          browser: false



