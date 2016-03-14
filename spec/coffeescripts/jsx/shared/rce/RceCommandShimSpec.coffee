define [
  'jsx/shared/rce/RceCommandShim',
  'helpers/fixtures'
], (RceCommandShim, fixtures) ->

  module 'RceCommandShim',
    setup: ->
      @shim = new RceCommandShim()
      fixtures.setup()
      @$target = fixtures.create('<textarea />')

    teardown: ->
      fixtures.teardown()

  test "just forwards through target's remoteEditor if set", ->
    remoteEditor = { call: sinon.stub().returns("methodResult") }
    @$target.data('remoteEditor', remoteEditor)
    equal @shim.send(@$target, "methodName", "methodArgument"), "methodResult"
    ok remoteEditor.call.calledWith("methodName", "methodArgument")

  test "uses editorBox if remoteEditor is not set but rich_text is set", ->
    sinon.stub(@$target, 'editorBox').returns("methodResult")
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', true)
    equal @shim.send(@$target, "methodName", "methodArgument"), "methodResult"
    ok @$target.editorBox.calledWith("methodName", "methodArgument")

  test "returns false for exists? if neither remoteEditor nor rich_text are set (e.g. load failed)", ->
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', null)
    equal @shim.send(@$target, "exists?"), false

  test "returns target's val() for get_code if neither remoteEditor nor rich_text are set (e.g. load failed)", ->
    @$target.data('remoteEditor', null)
    @$target.data('rich_text', null)
    @$target.val('current raw value')
    equal @shim.send(@$target, "get_code"), 'current raw value'
