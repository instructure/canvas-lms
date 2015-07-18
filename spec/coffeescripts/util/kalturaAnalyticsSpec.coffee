define [
  'jquery'
  'compiled/util/kalturaAnalytics'
  'vendor/mediaelement-and-player'
  'vendor/jquery.cookie'
], ($, kalturaAnalytics, mejs) ->
  module 'kaltura analytics helper',
    setup: ->
      @player = new mejs.PluginMediaElement
      @pluginSettings = {partner_id: 'ster', kcw_ui_conf: 'cobb', domain:'example.com', do_analytics:true, parallel_api_calls: 1}

    teardown: ->
      $('.kaltura-analytics').remove()
      $.cookie('kaltura_analytic_tracker', null, path: '/')

  test 'adds event listeners', ->
    @mock(@player).expects('addEventListener').atLeast(6)
    kalturaAnalytics("1", @player, @pluginSettings)

  test 'generate api url', ->
    ka = kalturaAnalytics("1", @player, @pluginSettings)
    if window.location.protocol is 'http:'
      equal ka.generateApiUrl(), 'http://example.com/api_v3/index.php?', 'generated bad url'
    else
      equal ka.generateApiUrl(), 'https://example.com/api_v3/index.php?', 'generated bad url'

  test 'queue new analytics call', ->
    ka = kalturaAnalytics("1", @player, @pluginSettings)
    exp = sinon.expectation.create([]).once()
    ka.iframes[0].pinger= exp
    ka.queueAnalyticEvent("oioi")
    if window.location.protocol is 'http:'
      equal ka.iframes[0].queue[0].indexOf('http://example.com/api_v3/index.php?service=stats&action=collect&event%3AentryId=1&event'), 0
    else
      equal ka.iframes[0].queue[0].indexOf('https://example.com/api_v3/index.php?service=stats&action=collect&event%3AentryId=1&event'), 0

    ok ka.iframes[0].queue[0].match(/eventType=oioi/)
    exp.verify()

  test "don't load if disabled", ->
    equal kalturaAnalytics("1", @player, {do_analytics:false}), null
    equal kalturaAnalytics("1", @player, {}), null
    equal kalturaAnalytics("1", @player, null), null

  # fragile spec
  # test 'session cookie is created', ->
  #   ka = kalturaAnalytics("1", @player, @pluginSettings)
  #   ok $.cookie('kaltura_analytic_tracker')
  #   equal ka.kaSession, $.cookie('kaltura_analytic_tracker')

  test 'iframe created', ->
    ka = kalturaAnalytics("1", @player, @pluginSettings)
    iframe = $('.kaltura-analytics')
    equal iframe.length, ka.iframes.length
    ok iframe.hasClass('hidden')
