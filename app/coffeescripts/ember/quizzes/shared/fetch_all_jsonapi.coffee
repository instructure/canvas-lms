define [
  'ember'
  'ic-ajax'
], ({$, ArrayProxy}, ajax) ->

  handlePagination = (result) ->
    {meta} = result.response
    {pagination} = meta
    records = result.response[meta.primaryCollection]

    if pagination.next
      ajax.raw(pagination.next).then(handlePagination).then (_newRecords) ->
        records.concat(_newRecords)
    else
      Em.RSVP.resolve(records)

  fetchAllPages = (url) ->
    ajax.raw(url).then(handlePagination)
