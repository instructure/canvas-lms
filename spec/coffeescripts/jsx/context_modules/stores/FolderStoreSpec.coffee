define ['jsx/context_modules/stores/FolderStore'], (store) ->
  module 'FolderStore',

  test 'constructor', ->
    folderStore = new store('tests/1')
    equal folderStore.apiEndpoint, '/api/v1/tests/1/folders?per_page=20', "Should have the proper endpoint"