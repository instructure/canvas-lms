define [
  'compiled/views/feature_flags/FeatureFlagView'
  'compiled/models/FeatureFlag'
  'jquery'
  'timezone'
  'vendor/timezone/America/Juneau'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (FeatureFlagView, FeatureFlag, $, tz, juneau, french, I18nStubber, fakeENV) ->

  module "FeatureFlagView",
    setup: ->
      @container = $('<div />', id: 'feature-flags').appendTo('#fixtures')
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      fakeENV.setup()

    teardown: ->
      @container.remove()
      tz.restore(@snapshot)
      I18nStubber.popFrame()
      fakeENV.teardown()

  test 'should format release date with locale-appropriate format string', ->
    releaseDate = tz.parse('2100-07-04T00:00:00Z')

    tz.changeLocale(french, 'fr_FR')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.medium': '%-d %b %Y'
      'date.abbr_month_names.7': 'juil.'

    flag = new FeatureFlag
      releaseOn: releaseDate
      feature_flag:
        transitions: {}
    view = new FeatureFlagView el: @container, model: flag
    view.render()

    equal view.$('.feature-release-date').text().trim(), '4 juil. 2100'

  test 'should format release date in locale-appropriate format string', ->
    releaseDate = tz.parse('2100-07-04T00:00:00Z')

    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'date.formats.medium': '%b %-d, %Y'
      'date.abbr_month_names.7': 'Jul'

    flag = new FeatureFlag
      releaseOn: releaseDate
      feature_flag:
        transitions: {}
    view = new FeatureFlagView el: @container, model: flag
    view.render()

    equal view.$('.feature-release-date').text().trim(), 'Jul 3, 2100'
