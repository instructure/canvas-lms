define([
  'jsx/webzip_export/reducer'
], (reducer) => {
  module('Webzip Exports Reducer')

  test('creates new export on CREATE_NEW_EXPORT', () => {
    const initialState = {
      exports: [{date: 'December 7, 1941 @ 8:00 AM', link: 'http://example.com/pearlharbor'}]
    }

    const newState = reducer(initialState, {
      type: 'CREATE_NEW_EXPORT',
      payload: {date: 'December 25, 1776 @ 10:00 PM', link: 'http://example.com/washingtoncrossingdelaware'}
    })

    equal(newState.exports.length, 2)
  })
})
