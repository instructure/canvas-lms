define ['jsx/context_modules/stores/FolderStore'], (store) ->
  QUnit.module 'FolderStore'

  test 'constructor', ->
    folderStore = new store('tests/1', {perPage:100})
    equal folderStore.apiEndpoint, '/api/v1/tests/1/folders?per_page=100', "Should have the proper endpoint"
