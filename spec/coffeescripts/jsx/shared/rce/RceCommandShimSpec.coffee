define [
  'jsx/shared/rce/RceCommandShim',
  'jsx/shared/rce/rceStore',
  'helpers/fixtures'
  'helpers/fakeENV'
], (RceCommandShim, RCEStore, fixtures, fakeENV) ->

  module 'RceCommandShim',
    setup: ->
      @shim = new RceCommandShim()
      fakeENV.setup()
      fixtures.setup()
      @$target = fixtures.create('<textarea />')
      sinon.spy(@$target, 'editorBox')
      sinon.stub(RCEStore, 'callOnTarget')

    teardown: ->
      fakeENV.teardown()
      fixtures.teardown()
      RCEStore.callOnTarget.restore()

  test 'uses editor box when feature flag contextually off', ->
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = false
    @shim.send(@$target, "someMethod")
    ok RCEStore.callOnTarget.notCalled
    ok @$target.editorBox.calledWith("someMethod")

  test 'goes through RCE store when feature flag contextually on', ->
    ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED = true
    @shim.send(@$target, "someMethod")
    ok @$target.editorBox.notCalled
    ok RCEStore.callOnTarget.calledWith(@$target, "someMethod")
