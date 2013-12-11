define [
  'ember'
  'ic-ajax'
  './parse_link_header'
], ({$, ArrayProxy}, ajax, parseLinkHeader) ->

  fetch = (url, records, data) ->
    opts = $.extend({dataType: "json"}, {data: data})
    ajax.raw(url, opts).then (result) ->
      records.pushObjects result.response
      meta = parseLinkHeader result.jqXHR
      if meta.next
        fetch meta.next, records, data

  fetchAllPages = (url, data) ->
    records = ArrayProxy.create({content: []})
    fetch url, records, data
    records
