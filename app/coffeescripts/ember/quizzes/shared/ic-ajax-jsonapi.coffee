define [
  'ic-ajax'
  'jquery'
], (ajax, $) ->

  # Wrapper for ic-ajax that defaults to JSONAPI options for the jQuery
  # options hash.
  jsonapiAjax = (url, opts) ->
    options =
      dataType: 'json'
      contentType: 'application/json'
      headers:
        'Accepts': 'application/vnd.api+json'
    newArguments = if arguments.length is 1
      if typeof url is 'string'
        $.extend(true, options, url: url)
      else if typeof url is 'object'
        $.extend(true, options, url)
    else
      $.extend(true, options, url: url, opts)

    ajax.call null, newArguments
