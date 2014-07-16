define ['ember'], (Ember) ->

  getACoupleFolders = (parentFolder) ->
    folders = []
    Ember.run.later (->
      folders.addObjects [
        mockFolder(parentFolder)
        mockFolder(parentFolder)
      ]
      return
    ), 500
    folders

  getACoupleFiles = (parentFolder) ->
    files = []
    Ember.run.later (->
      files.addObjects [
        mockFile(parentFolder)
        mockFile(parentFolder)
        mockFile(parentFolder)
      ]
      return
    ), 500
    files

  getChar = -> String.fromCharCode (charCounter++ % 26) + 97

  mockFolder = (parentFolder) ->
    Folder.create
      parentFolder: parentFolder
      context_id: 1
      context_type: "User"
      created_at: "2014-02-18T23:22:10Z"
      full_name: "my files"
      id: 1
      lock_at: null
      name: "folder_" + getChar()
      parent_folder_id: null
      position: null
      unlock_at: null
      updated_at: "2014-02-18T23:22:10Z"
      locked: false
      folders_url: "http://localhost:3000/api/v1/folders/1/folders"
      files_url: "http://localhost:3000/api/v1/folders/1/files"
      files_count: 0
      folders_count: 0
      hidden: null
      locked_for_user: false
      hidden_for_user: false

  mockFile = (parentFolder) ->
    size: 4
    "content-type": "text/plain"
    url: "http://www.example.com/files/569/download?download_frd=1&verifier=c6HdZmxOZa0Fiin2cbvZeI8I5ry7yqD7RChQzb6P"
    id: 569
    name: "file_" + getChar()
    created_at: "2012-07-06T14:58:50Z"
    updated_at: "2012-07-06T14:58:50Z"
    unlock_at: null
    locked: false
    hidden: false
    lock_at: null
    locked_for_user: false
    lock_info:
      asset_string: "file_569"
      unlock_at: "2013-01-01T00:00:00-06:00"
      lock_at: "2013-02-01T00:00:00-06:00"
      context_module: {}
      manually_locked: true

    lock_explanation: "This assignment is locked until September 1 at 12:00am"
    hidden_for_user: false
    thumbnail_url: null
    parentFolder: parentFolder

  Folder = Ember.Object.extend

    fetchFolders: ->
      @set("folders", getACoupleFolders(this)) unless @get("folders")

    fetchChildren: ->
      debugger
      @fetchFolders()
      @set("files", getACoupleFiles(this)) unless @get("files")

    path: Ember.computed ->
      parentPath = (if @parentFolder then @parentFolder.get("path") + "/" else "")
      parentPath + @get("name")

    children: Ember.computed "files.@each.name", "folders.@each.name", ->
      debugger
      (@get("folders") or []).concat @get("files") or []
