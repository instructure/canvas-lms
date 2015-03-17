define ['jsx/context_modules/stores/FileStore'], (store) ->
  module 'FileStore',

  test 'constructor', ->
    fileStore = new store('tests/1')
    equal fileStore.apiEndpoint, '/api/v1/tests/1/files?per_page=20', "Should have the proper endpoint"