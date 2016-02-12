define [
  'helpers/fakeENV'
  'jsx/shared/rce/loadNewRCE'
  'jsx/shared/rce/serviceRCELoader'
], (fakeENV, loadNewRCE, serviceRCELoader) ->

  module 'loadRCE: RCS Enabled with host',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      ENV.RICH_CONTENT_APP_HOST = "http://fakehost.com"
      @originalLoadOnTarget = serviceRCELoader.loadOnTarget
      serviceRCELoader.loadOnTarget = sinon.stub()
    teardown: ->
      serviceRCELoader.loadOnTarget = @originalLoadOnTarget
      fakeENV.teardown()

  test 'calls serviceRCELoader.loadOnTarget with a target and host', ->
    loadNewRCE("fakeTarget", {})
    ok serviceRCELoader.loadOnTarget.calledWith("fakeTarget", {}, "http://fakehost.com")

  test 'CDN host overrides app host', ->
    ENV.RICH_CONTENT_CDN_HOST = "http://fakecdn.net"
    loadNewRCE("fakeTarget", {})
    ok serviceRCELoader.loadOnTarget.calledWith("fakeTarget", {}, "http://fakecdn.net")

  module 'loadRCE: RCS Disabled',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = false
    teardown: ->
      fakeENV.teardown()

  test 'calls editorBox and set_code', ->
    secondStub = sinon.stub()
    ebStub = sinon.stub().returns({editorBox: secondStub})
    fakeTarget =
      editorBox: ebStub
    opts =
      defaultContent: "content"

    loadNewRCE(fakeTarget, opts)
    ok ebStub.called
    ok secondStub.calledWith('set_code', "content")
