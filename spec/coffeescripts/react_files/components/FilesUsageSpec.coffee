
define [
  'react'
  'jquery'
  'jsx/files/FilesUsage'
], (React, $, FilesUsage) ->
  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate

  module 'FilesUsage#update',

    filesUpdateTest: (props, test) ->
      @server = sinon.fakeServer.create()
      @filesUsage = TestUtils.renderIntoDocument(FilesUsage(props))

      test()

      React.unmountComponentAtNode(@filesUsage.getDOMNode().parentNode)

      @server.restore()

  test "makes a get request with contextType and contextId", ->
    @stub($, 'get')
    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
       @filesUsage.update()
       ok $.get.calledWith(@filesUsage.url()), "makes get request with correct params"

  test "sets state with ajax requests returned data", ->
    data = {foo: 'bar'}

    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
      @server.respondWith @filesUsage.url(), [
        200
        'Content-Type': 'application/json'
        JSON.stringify data
      ]

      @spy(@filesUsage, 'setState')

      @filesUsage.update()
      @server.respond()

      ok @filesUsage.setState.calledWith(data), 'called set state with returned get request data'

  test 'update called after component mounted', ->
    @filesUpdateTest {contextType: 'users', contextId: 4}, =>
      @stub(@filesUsage, 'update').returns(true)
      @filesUsage.componentDidMount()
      ok @filesUsage.update.calledOnce, "called update after it mounted"
