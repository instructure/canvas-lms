define [
  'react'
  'compiled/react_files/components/UploadDropZone'
], (React, UploadDropZone) ->

  Simulate = React.addons.TestUtils.Simulate

  node = document.querySelector('#fixtures')

  module 'UploadDropZone',
    setup: ->
      @uploadZone = React.render(UploadDropZone({}), node)

    teardown: ->
      React.unmountComponentAtNode(node)

  test 'displays nothing by default', ->
    displayText = @uploadZone.getDOMNode().innerHTML.trim()
    equal(displayText, '')

  test 'displays dropzone when active', ->
    @uploadZone.setState({active: true})
    ok(@uploadZone.getDOMNode().querySelector('.UploadDropZone__instructions'))

  test 'handles drop event on target', ->
    @stub(@uploadZone, 'onDrop')

    @uploadZone.setState({active: true})
    dataTransfer = {
      types: ['Files']
    }

    n = @uploadZone.getDOMNode()
    Simulate.dragEnter(n, {dataTransfer: dataTransfer})
    Simulate.dragOver(n, {dataTransfer: dataTransfer})
    Simulate.drop(n)
    ok(@uploadZone.onDrop.calledOnce, 'handles file drops')
