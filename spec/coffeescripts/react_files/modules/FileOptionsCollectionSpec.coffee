define [
  'compiled/react_files/modules/FileOptionsCollection'
], (FileOptionsCollection) ->

  mockFile = (name, type='application/image') ->
      get: (attr) ->
        if attr == 'display_name'
          return name
      type: type

  setupFolderWith = (names) ->
    mockFiles = names.map (name) ->
      mockFile(name)
    folder = {
      files: {
        models: mockFiles
      }
    }
    FileOptionsCollection.setFolder(folder)

  createFileOption = (fileName, dup, optionName) ->
    options =
      file:
        name: fileName
    options.dup = dup if dup
    options.name = optionName if optionName
    options

  module 'FileOptionsCollection',
    setup: ->
      FileOptionsCollection.resetState()

    teardown: ->
      FileOptionsCollection.resetState()

    test 'fileNameExists correctly finds existing files by display_name', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      ok FileOptionsCollection.fileNameExists('foo')

    test 'fileNameExists returns falsy value when no matching file exists', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      equal FileOptionsCollection.fileNameExists('xyz')?, false

    test 'segregateOptionBuckets divides files into collsion and resolved buckets', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      one = createFileOption('file_name.txt', 'overwrite', 'option_name.txt')
      two = createFileOption('foo')
      {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one, two])
      equal collisions.length, 1
      equal resolved.length, 1
      equal collisions[0].file.name, 'foo'

    test 'segregateOptionBuckets uses fileOptions name over actual file name', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      one = createFileOption('file_name.txt', 'rename', 'foo')
      {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
      equal collisions.length, 1
      equal resolved.length, 0
      equal collisions[0].file.name, 'file_name.txt'

    test 'segregateOptionBuckets name conflicts marked as overwrite are considered resolved', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      one = createFileOption('foo', 'overwrite')
      {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
      equal collisions.length, 0
      equal resolved.length, 1
      equal resolved[0].file.name, 'foo'

    test 'segregateOptionBuckets detects zip files', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      one = createFileOption('other.zip')
      one.file.type = 'application/zip'
      {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
      equal resolved.length, 0
      equal zips[0].file.name, 'other.zip'

    test 'segregateOptionBuckets ignores zip files that have an expandZip option', ->
      setupFolderWith(['foo', 'bar', 'baz'])
      one = createFileOption('other.zip')
      one.file.type = 'application/zip'
      one.expandZip = false
      {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
      equal resolved.length, 1
      equal zips.length, 0

    test 'segregateOptionBuckets ignores zip file names when expandZip option is true', ->
      setupFolderWith(['other.zip', 'bar', 'baz'])
      one = createFileOption('other.zip')
      one.file.type = 'application/zip'
      one.expandZip = true
      {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
      equal resolved.length, 1
      equal collisions.length, 0
      equal zips.length, 0
