define [
  'react'
  'jquery'
  'compiled/react_files/components/UploadButton'
  'compiled/models/Folder'
  'compiled/models/File'
], (React, $, UploadButton, Folder, File) ->

  Simulate = React.addons.TestUtils.Simulate

  button = null


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
