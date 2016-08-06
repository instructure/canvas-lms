define [
  'underscore'
  '../modules/UploadQueue'
  'react-dom'
], (_, UploadQueue, ReactDOM) ->

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
      resolvedNames: []
      nameCollisions: []
      zipOptions: []
      newOptions: false

    queueUploads: (contextId, contextType) ->
      @state.resolvedNames.forEach (f) =>
        UploadQueue.enqueue(f, @folder, contextId, contextType)
      @setState({newOptions: false})

    toFilesOptionArray: (fList) ->
      [].slice.call(fList, 0).map((file) -> {file})

    fileNameExists: (name) ->
      _.find @folder.files.models, (f) -> f.get('display_name') is name

    isZipFile: (file) ->
      !!file.type?.match(/zip/)

    # divide into existing naming collisions and resolved ones
    segregateOptionBuckets: (selectedFiles) ->
      [collisions, resolved, zips] = [[], [], []]
      for file in selectedFiles
        nameToTest = file.name || file.file.name
        if (@isZipFile(file.file) and typeof file.expandZip is 'undefined')
          zips.push file
        # only mark as collision if it is a collision that hasn't been resolved, or is is a zip that will be expanded
        else if @fileNameExists(nameToTest) && (file.dup != 'overwrite' && (!file.expandZip? || file.expandZip is false))
          collisions.push file
        else
          resolved.push file

      {collisions, resolved, zips}

    handleAddFilesClick: ->
      ReactDOM.findDOMNode(this.refs.addFileInput).click()

    handleFilesInputChange: (e) ->
      selectedFiles = @toFilesOptionArray(ReactDOM.findDOMNode(this.refs.addFileInput).files)
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

    setOptionsFromFiles: (files, notifyChange) ->
      allOptions = @toFilesOptionArray(files)
      {resolved, collisions, zips} = @segregateOptionBuckets(allOptions)
      @setState({nameCollisions: collisions, resolvedNames: resolved, zipOptions: zips, newOptions: true})
      if notifyChange && @onChange
        @onChange()

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

    onChange: ->
      #noop

  new FileOptionsCollection()
