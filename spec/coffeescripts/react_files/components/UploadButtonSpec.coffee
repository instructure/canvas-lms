define [
  'react'
  'jquery'
  'compiled/react_files/components/UploadButton'
  'compiled/models/Folder'
  'compiled/models/File'
], (React, $, UploadButton, Folder, File) ->

  Simulate = React.addons.TestUtils.Simulate

  button = null

  mockFile = (name) ->
      get: (attr) ->
        if attr == 'display_name'
          return name

  setupFolderWith = (names) ->
    mockFiles = names.map (name) ->
      mockFile(name)
    button.props.currentFolder.files.models = mockFiles

  createFileOption = (fileName, dup, optionName) ->
    options =
      file:
        name: fileName
    options.dup = dup if dup
    options.name = optionName if optionName
    options

  module 'UploadButton',
    setup: ->
      props =
        currentFolder:
          files:
            models: []

      button = React.renderComponent(UploadButton(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(button.getDOMNode().parentNode)

  test 'hides actual file input form', ->
    form = button.refs.form.getDOMNode()
    ok $(form).attr('class').match(/hidden/), 'is hidden from user'

  test 'fileNameExists correctly finds existing files by display_name', ->
    setupFolderWith(['foo', 'bar', 'baz'])
    ok button.fileNameExists('foo')

  test 'fileNameExists returns falsy value when no matching file exists', ->
    setupFolderWith(['foo', 'bar', 'baz'])
    equal button.fileNameExists('xyz')?, false

  test 'segregateCollisions divides files into collsion and resolved buckets', ->
    setupFolderWith(['foo', 'bar', 'baz'])
    one = createFileOption('file_name.txt', 'overwrite', 'option_name.txt')
    two = createFileOption('foo')
    {collisions, resolved} = button.segregateCollisions([one, two])
    equal collisions.length, 1
    equal resolved.length, 1
    equal collisions[0].file.name, 'foo'

  test 'segregationCollisions uses fileOptions name over actual file name', ->
    setupFolderWith(['foo', 'bar', 'baz'])
    one = createFileOption('file_name.txt', 'rename', 'foo')
    {collisions, resolved} = button.segregateCollisions([one])
    equal collisions.length, 1
    equal resolved.length, 0
    equal collisions[0].file.name, 'file_name.txt'

  test 'segregateCollisions name conflicts marked as overwrite are considered resolved', ->
    setupFolderWith(['foo', 'bar', 'baz'])
    one = createFileOption('foo', 'overwrite')
    {collisions, resolved} = button.segregateCollisions([one])
    equal collisions.length, 0
    equal resolved.length, 1
    equal resolved[0].file.name, 'foo'
    ok(true)
