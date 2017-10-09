#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/util/brandableCss'
], ($, brandableCss) ->

  testBundleId = 'bundles/foo'
  testFingerprint = 'asdf1234'

  stubENV = ->
    window.ENV ||= {}
    window.ENV.ASSET_HOST = 'http://cdn.example.com'
    window.ENV.use_high_contrast = true

  QUnit.module 'brandableCss.loadStylesheet'
  test 'should load correctly', ->
    brandableCss.loadStylesheet(testBundleId, {combinedChecksum: testFingerprint})
    expectedHref = "#{window.ENV.ASSET_HOST || ''}/dist/brandable_css/new_styles_normal_contrast/#{testBundleId}-#{testFingerprint}.css"
    equal $('head link[rel="stylesheet"]:last').attr('href'), expectedHref

  QUnit.module 'brandableCss.getCssVariant'
  test 'should be new_styles_normal_contrast by default', ->
    window.ENV.use_new_typography = undefined
    equal brandableCss.getCssVariant(), 'new_styles_normal_contrast'

  test 'should be new_typography_normal_contrast by if env var from feature flag is set', ->
    window.ENV.use_new_typography = true
    equal brandableCss.getCssVariant(), 'new_typography_normal_contrast'

  test 'should pick up ENV settings', ->
    window.ENV.use_new_typography = undefined
    stubENV()
    equal brandableCss.getCssVariant(), 'new_styles_high_contrast'

  test 'should pick up ENV & new_typography', ->
    stubENV()
    window.ENV.use_new_typography = true
    equal brandableCss.getCssVariant(), 'new_typography_high_contrast'

  QUnit.module 'brandableCss.urlFor'
  test 'should have right default', ->
    window.ENV = {}
    expected = "/dist/brandable_css/new_styles_normal_contrast/#{testBundleId}-#{testFingerprint}.css"
    equal brandableCss.urlFor(testBundleId, {combinedChecksum: testFingerprint}), expected

  test 'should handle no_variables correctly', ->
    equal brandableCss.urlFor(testBundleId, {
      combinedChecksum: testFingerprint,
      includesNoVariables: true
    }), "/dist/brandable_css/no_variables/#{testBundleId}-#{testFingerprint}.css"

  test 'should pick up ENV settings', ->
    stubENV()
    window.ENV.use_high_contrast = false
    expected = "http://cdn.example.com/dist/brandable_css/new_styles_normal_contrast/#{testBundleId}-#{testFingerprint}.css"
    equal brandableCss.urlFor(testBundleId,{combinedChecksum: testFingerprint}), expected

  test 'should pick up ENV settings & new typography feature flag', ->
    stubENV()
    window.ENV.use_new_typography = true
    expected = "http://cdn.example.com/dist/brandable_css/new_typography_high_contrast/#{testBundleId}-#{testFingerprint}.css"
    equal brandableCss.urlFor(testBundleId,{combinedChecksum: testFingerprint}), expected
