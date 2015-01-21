
define [
  'old_unsupported_dont_use_react'
  'jquery'
  'compiled/react_files/components/FilesUsage'
], (React, $, FilesUsage) ->
  Simulate = React.addons.TestUtils.Simulate

  filesUpdateTest = (props, test) ->
    @filesUsage = React.renderComponent(FilesUsage(props), $('<div>').appendTo('body')[0])

    test()

    React.unmountComponentAtNode(@filesUsage.getDOMNode().parentNode)

  module 'FilesUsage#update',
  test "makes a get request with contextType and contextId", ->
    sinon.stub($, 'get')
    filesUpdateTest {contextType: 5, contextId: 4}, ->
       @filesUsage.update()
       ok $.get.calledWith("/api/v1/5/4/files/quota"), "makes get request with correct params"
    $.get.restore()

  test "sets state with ajax requests returned data", ->
    data = {foo: 'bar'}
    server = sinon.fakeServer.create()

    server.respondWith "/api/v1/5/4/files/quota", [
      200
      'Content-Type': 'application/json'
      JSON.stringify data
    ]

    filesUpdateTest {contextType: 5, contextId: 4}, ->
      sinon.spy(@filesUsage, 'setState')

      @filesUsage.update()
      server.respond()

      ok @filesUsage.setState.calledWith(data), 'called set state with returned get request data'

      @filesUsage.setState.restore()

    server.restore()

  test 'update called after component mounted', ->

    filesUpdateTest {contextType: 5, contextId: 4}, ->
      sinon.stub(@filesUsage, 'update')
      @filesUsage.componentDidMount()
      ok @filesUsage.update.calledOnce, "called update after it mounted"
      @filesUsage.update.restore()

