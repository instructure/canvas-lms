define [
  'underscore'
  '../modules/UploadQueue'
], (_, UploadQueue) ->

  ###
  Manages buckets of FileOptions (resolved, nameCollisions, zipOptions)

  FileOption:
    file: <File>
    dup: how to handle duplicate names rename || overwrite (used in api call)
    name: name by which to upload the file
    expandZip: (bool) upload the zip or expand it to current directory
  ###

  class FileOptionsCollection

    constructor: ->
      @state = @buildDefaultState()

    buildDefaultState: ->
      return {
        resolvedNames: []
        nameCollisions: []
        zipOptions: []
        newOptions: false
      }

    queueUploads: (contextId, contextType) ->
      @state.resolvedNames.forEach (f) =>
        UploadQueue.enqueue(f, @folder, contextId, contextType)
      @setState({newOptions: false})

    toFilesOptionArray: (fList) ->
      files = []
      i = 0
      while i < fList.length
        files.push {file: fList.item(i)}
        i++
      files

    fileNameExists: (name) ->
      found = _.find @folder.files.models, (f) ->
        f.get('display_name') == name

    isZipFile: (file) ->
      !!file.type?.match(/zip/)

    # divide into existing naming collisions and resolved ones
    segregateOptionBuckets: (selectedFiles) ->
      i = 0
      collisions = []
      resolved = []
      zips = []
      while i < selectedFiles.length
        fileOptions = selectedFiles[i]
        nameToTest = fileOptions.name || fileOptions.file.name
        # only mark as collision if it is a collision that hasn't been resolved, or is is a zip that will be expanded
        if @fileNameExists(nameToTest) && (fileOptions.dup != 'overwrite' && (!fileOptions.expandZip? || fileOptions.expandZip == false))
          collisions.push fileOptions
        else if (@isZipFile(fileOptions.file) && fileOptions.expandZip == undefined)
          zips.push fileOptions
        else
          resolved.push fileOptions
        i++
      {collisions:collisions, resolved:resolved, zips:zips}

    handleAddFilesClick: ->
      this.refs.addFileInput.getDOMNode().click()

    handleFilesInputChange: (e) ->
      selectedFiles = @toFilesOptionArray(this.refs.addFileInput.getDOMNode().files)
      {resolved, collisions, zips} = @segregateOptionBuckets(selectedFiles)
      @setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})

    onNameConflictResolved: (fileNameOptions) ->
      nameCollisions = @state.nameCollisions
      resolvedNames = @state.resolvedNames
      zips = @state.zipOptions

      resolvedNames.push fileNameOptions
      # TODO: only difference is that we remove the first nameCollision here
      nameCollisions.shift()

      # redo conflict resolution, new name from user could still conflict
      allOptions = resolvedNames.concat(nameCollisions).concat(zips)
      {resolved, collisions, zips} = @segregateOptionBuckets(allOptions)
      @setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})

    onZipOptionsResolved: (fileNameOptions) ->
      nameCollisions = @state.nameCollisions
      resolvedNames = @state.resolvedNames
      zips = @state.zipOptions

      resolvedNames.push fileNameOptions
      # TODO: only difference is that we remove the first zip here
      zips.shift()

      # redo conflict resolution, new name from user could still conflict
      allOptions = resolvedNames.concat(nameCollisions).concat(zips)
      {resolved, collisions, zips} = @segregateOptionBuckets(allOptions)
      @setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips})

    setOptionsFromFiles: (files) ->
      allOptions = @toFilesOptionArray(files)
      {resolved, collisions, zips} = @segregateOptionBuckets(allOptions)
      @setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips, newOptions: true})

    hasNewOptions: ->
      return @state.newOptions

    setFolder: (folder) ->
      @folder = folder

    getFolder: ->
      return @folder

    setState: (options) ->
      @state = _.defaults(options, @state)

    getState: ->
      return @state

    resetState: ->
      @state = @buildDefaultState()

  new FileOptionsCollection()
