define [
  'ember'
  'ic-ajax'
  './parse_link_header'
], ({$, ArrayProxy}, ajax, parseLinkHeader) ->

  fetch = (url, options) ->
    opts = $.extend({dataType: "json"}, {data: options.data})
    records = options.records
    ajax.raw(url, opts).then (result) ->
      response = if options.process
        options.process(result.response)
      else
        result.response
      records.pushObjects response
      meta = parseLinkHeader result.jqXHR
      if meta.next
        fetch meta.next, options
      else
        records.set('isLoaded', true)
        records.set('isLoading', false)
        records

  fetchAllPages = (url, options = {}) ->
    records = options.records ||= ArrayProxy.create({content: []})
    records.set('isLoading', true)
    records.set('promise', fetch(url, options))
    records
