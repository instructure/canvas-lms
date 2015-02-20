
define [
  'old_unsupported_dont_use_react'
  'jquery'
  'compiled/react_files/components/FilesUsage'
], (React, $, FilesUsage) ->
  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate

  filesUpdateTest = (props, test) ->
    @server = sinon.fakeServer.create()
    @filesUsage = TestUtils.renderIntoDocument(FilesUsage(props))

    test()

    React.unmountComponentAtNode(@filesUsage.getDOMNode().parentNode)

    @server.restore()

  module 'FilesUsage#update',
  test "makes a get request with contextType and contextId", ->
    sinon.stub($, 'get')
    filesUpdateTest {contextType: 'users', contextId: 4}, ->
       @filesUsage.update()
       ok $.get.calledWith(@filesUsage.url()), "makes get request with correct params"
    $.get.restore()

  test "sets state with ajax requests returned data", ->
    data = {foo: 'bar'}

    filesUpdateTest {contextType: 'users', contextId: 4}, ->
      @server.respondWith @filesUsage.url(), [
        200
        'Content-Type': 'application/json'
        JSON.stringify data
      ]

      sinon.spy(@filesUsage, 'setState')

      @filesUsage.update()
      @server.respond()

      ok @filesUsage.setState.calledWith(data), 'called set state with returned get request data'

      @filesUsage.setState.restore()

  test 'update called after component mounted', ->
    filesUpdateTest {contextType: 'users', contextId: 4}, ->
      sinon.stub(@filesUsage, 'update').returns(true)
      @filesUsage.componentDidMount()
      ok @filesUsage.update.calledOnce, "called update after it mounted"
      @filesUsage.update.restore()

