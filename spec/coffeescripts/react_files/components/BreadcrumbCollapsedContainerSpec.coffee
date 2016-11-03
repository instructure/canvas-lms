define [
  'jquery'
  'react'
  'react-dom'
  'jsx/files/BreadcrumbCollapsedContainer'
  'compiled/models/Folder'
  'compiled/react_files/modules/filesEnv'
  '../mockFilesENV'
  '../../helpers/stubRouterContext'
], ($, React, ReactDOM, BreadcrumbCollapsedContainer, Folder, filesEnv, mockFilesENV, stubRouterContext) ->
  simulate = React.addons.TestUtils.Simulate
  simulateNative = React.addons.TestUtils.SimulateNative
  TestUtils = React.addons.TestUtils

  module 'BreadcrumbsCollapsedContainer',
    setup: ->
      folder = new Folder(name: 'Test Folder', urlPath: 'test_url', url: 'stupid')
      folder.url = -> "stupid"
      props = foldersToContain: [folder]

      bcc = stubRouterContext(BreadcrumbCollapsedContainer, props)
      @bcc = TestUtils.renderIntoDocument(React.createElement(bcc))

    teardown: ->
      ReactDOM.unmountComponentAtNode(@bcc.getDOMNode().parentNode)

  test 'BCC: opens breadcumbs on mouse enter', ->
    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOver(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: opens breadcrumbs on focus', ->
    $node = $(@bcc.getDOMNode())
    simulate.focus(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: closes breadcrumbs on mouse leave', ->
    clock = sinon.useFakeTimers()

    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOut(@bcc.getDOMNode())
    clock.tick(200)
    equal $node.find('.closed').length, 1, "should have class of closed"

    clock.restore()

  test 'BCC: closes breadcrumbs on blur', ->
    clock = sinon.useFakeTimers()
    simulate.blur(@bcc.getDOMNode())
    clock.tick(200)

    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOut(@bcc.getDOMNode())
    clock.tick(200)
    equal $node.find('.closed').length, 1, "should have class of closed"

    clock.restore()

