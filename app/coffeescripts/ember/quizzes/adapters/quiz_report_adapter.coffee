define [
  'ember'
  './jsonapi_adapter'
], ({get,set}, JSONAPIAdapter) ->
  JSONAPIAdapter.extend
    buildURL: (type, id) ->
      store = @container.lookup('store:main')
      store.getById('quizReport', id).get('url')