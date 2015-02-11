define [
  'jquery'
  'compiled/util/brandableCss'
], ($, brandableCss) ->

  testBundleId = 'bundles/foo-asdf1234'

  stubENV = ->
    window.ENV ||= {}
    window.ENV.active_brand_config = "brand_config_id"
    window.ENV.ASSET_HOST = 'http://cdn.example.com'
    window.ENV.use_new_styles = true
    window.ENV.use_high_contrast = true

  module 'brandableCss.loadStylesheet'
  test 'should load correctly', ->
    brandableCss.loadStylesheet(testBundleId)
    ok $('head link[rel="stylesheet"]:last').attr('href').match(testBundleId)

  module 'brandableCss.getCssVariant'
  test 'should be legacy_normal_contrast by default', ->
    equal brandableCss.getCssVariant(), 'legacy_normal_contrast'

  test 'should pick up ENV settings', ->
    stubENV()
    equal brandableCss.getCssVariant(), 'new_styles_high_contrast'

  module 'brandableCss.urlFor'
  test 'should have right default', ->
    window.ENV = {}
    expected = "/dist/brandable_css/legacy_normal_contrast/#{testBundleId}.css"
    equal brandableCss.urlFor(testBundleId), expected

  test 'should pick up ENV settings', ->
    stubENV()
    window.ENV.use_high_contrast = false
    expected = "http://cdn.example.com/dist/brandable_css/#{window.ENV.active_brand_config}/new_styles_normal_contrast/#{testBundleId}.css"
    equal brandableCss.urlFor(testBundleId), expected