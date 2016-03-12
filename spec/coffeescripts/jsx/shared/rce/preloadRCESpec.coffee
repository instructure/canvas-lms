define [
  'jsx/shared/rce/preloadRCE',
  'jsx/shared/rce/serviceRCELoader',
  'helpers/fakeENV'
], (preloadRCE, serviceRCELoader, fakeENV) ->

  module 'preloadRCE',
    setup: ->
      fakeENV.setup()
      ENV.RICH_CONTENT_SERVICE_ENABLED = true
      @preloadSpy = sinon.spy(serviceRCELoader, "preload");

    teardown: ->
      fakeENV.teardown()
      serviceRCELoader.preload.restore()

  test 'loads with CDN host if available', ->
    ENV.RICH_CONTENT_CDN_HOST = "cdn-host"
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    preloadRCE()
    ok @preloadSpy.calledWith("cdn-host")

  test 'uses app host if no cdn host', ->
    ENV.RICH_CONTENT_CDN_HOST = undefined
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    preloadRCE()
    ok @preloadSpy.calledWith("app-host")

  test 'does nothing when service disabled', ->
    ENV.RICH_CONTENT_SERVICE_ENABLED = undefined
    ENV.RICH_CONTENT_CDN_HOST = "cdn-host"
    ENV.RICH_CONTENT_APP_HOST = "app-host"
    ok @preloadSpy.notCalled
