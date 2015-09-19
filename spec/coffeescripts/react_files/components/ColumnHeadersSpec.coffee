define [
  'react'
  'jsx/files/ColumnHeaders'
], (React, ColumnHeaders) ->

  module 'ColumnHeaders'

  test '`queryParamsFor` returns correct values', ->
    SORT_UPDATED_AT_DESC = {sort: 'updated_at', order: 'desc'}
    queryParamsFor = ColumnHeaders.type.prototype.queryParamsFor

    deepEqual queryParamsFor({}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was not sorted by anything'
    deepEqual queryParamsFor({sort: 'created_at', order: 'desc'}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by other column'
    deepEqual queryParamsFor({sort: 'updated_at', order: 'asc' }, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by this column ascending'
    deepEqual queryParamsFor({sort: 'updated_at', order: 'desc'}, 'updated_at'), {sort: 'updated_at', order: 'asc'}
