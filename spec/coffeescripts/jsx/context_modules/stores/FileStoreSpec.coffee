define ['jsx/context_modules/stores/FileStore'], (store) ->
  QUnit.module 'FileStore'

  test 'constructor', ->
    fileStore = new store('tests/1', {perPage:100})
    equal fileStore.apiEndpoint, '/api/v1/tests/1/files?per_page=100', "Should have the proper endpoint"
