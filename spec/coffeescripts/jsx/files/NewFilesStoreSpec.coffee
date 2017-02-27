define ['jsx/files/NewFilesStore'], (NewFilesStore) ->

  QUnit.module 'NewFilesStore'

  test 'constructor', ->
    store = new NewFilesStore()
    ok store, "constructs properly"
    equal store.files.length, 0, 'files is initally empty'
    equal store.folders.length, 0, 'folders is initally empty'

  test 'adds single folder to store', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}])
    equal store.folders.length, 1, 'store length is one'

  test 'adds multiple folders to the store', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}, {id: 2}])
    equal store.folders.length, 2, 'store length is two'

  test 'doesn\'t add duplicates to the store', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}])
    store.addFolders([{id: 1}])
    equal store.folders.length, 1, 'store length is one'

  test 'triggers change when adding folders', ->
    store = new NewFilesStore()
    called = false
    store.addChangeListener () ->
      called = true
    store.addFolders([{id: 1}])
    ok called, 'change listener handler was called'

  test 'removes single folder from the store', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}])
    store.removeFolders([{id: 1}])
    equal store.folders.length, 0, 'store contains no folders'

  test 'removes multiple folders from the store', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}, {id: 2}, {id: 3}])
    store.removeFolders([{id: 1}, {id: 2}])
    equal store.folders.length, 1, 'store contains one folder after deletion'
    deepEqual store.folders[0], {id: 3}, 'store contains folder with id 3 after deletion'

  test 'adds single file to store', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1, parent_folder_id: 1}])
    equal store.files.length, 1, 'file store length is one'

  test 'adds multiple files to the store', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1, parent_folder_id: 1}, {id: 2, parent_folder_id: 1}])
    equal store.files.length, 2, 'store length is two'

  test 'doesn\'t add duplicates to the store', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1, parent_folder_id: 1}])
    store.addFiles([{id: 1, parent_folder_id: 1}])
    equal store.files.length, 1, 'store length is one'

  test 'triggers change when adding files', ->
    store = new NewFilesStore()
    called = false
    store.addChangeListener () ->
      called = true
    store.addFiles([{id: 1, parent_folder_id: 1}])
    ok called, 'change listener handler was called'

  test 'removes single file from the store', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1, parent_folder_id: 1}])
    store.removeFiles([{id: 1, parent_folder_id: 1}])
    equal store.files.length, 0, 'store contains no files'

  test 'removes multiple files from the store', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1, parent_folder_id: 1}, {id: 2, parent_folder_id: 1}, {id: 3, parent_folder_id: 1}])
    store.removeFiles([{id: 1, parent_folder_id: 1}, {id: 2, parent_folder_id: 1}])
    equal store.files.length, 1, 'store contains one file after deletion'
    deepEqual store.files[0], {id: 3, parent_folder_id: 1}, 'store contains file with id 3 after deletion'

  test 'triggers change when removing folders', ->
    store = new NewFilesStore()
    store.addFolders([{id: 1}])

    called = false
    store.addChangeListener () ->
      called = true
    store.removeFolders([{id: 1}])
    ok called, 'change listener handler was called'

  test 'triggers change when removing files', ->
    store = new NewFilesStore()
    store.addFiles([{id: 1}])

    called = false
    store.addChangeListener () ->
      called = true
    store.removeFiles([{id: 1}])
    ok called, 'change listener handler was called'
