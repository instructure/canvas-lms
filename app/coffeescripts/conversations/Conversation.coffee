define [
  'Backbone'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
], (Backbone) ->

  class Conversation extends Backbone.Model

    # NOTE: This class should be considered deprecated. Please be careful
    # when modifying it, especially adding functionality.
    #
    # Try adding to app/coffeescripts/models/Conversation.coffee first,
    # which is a version of this model that uses the API.

    defaults:
      audience: []

    # we don't currently save the model directly, rather we do inbox actions
    inboxAction: (options) ->
      defaults =
        url: @url()
        method: 'POST'
        success: (data) => @list.updateItem(data)
      options = $.extend(true, {}, defaults, options)
      options.data = $.extend(@list.baseData(), options.data ? {})
      ajaxRequest = $.ajaxJSON options.url, options.method, options.data, (data) =>
        options.success?(data)
        @list.updateItem(data)
      # TODO: use $el
      @list.$item(@id)?.disableWhileLoading(ajaxRequest)

    url: (action='') -> "/conversations/#{@id}/#{action}?#{$.param(@list.baseData())}"
