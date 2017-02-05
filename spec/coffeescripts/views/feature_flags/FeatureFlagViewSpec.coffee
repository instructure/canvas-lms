define [
  'compiled/views/feature_flags/FeatureFlagView'
  'compiled/models/FeatureFlag'
  'jquery'
  'timezone'
  'timezone/America/Juneau'
  'timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (FeatureFlagView, FeatureFlag, $, tz, juneau, french, I18nStubber, fakeENV) ->

  QUnit.module "FeatureFlagView",
    setup: ->
      @container = $('<div />', id: 'feature-flags').appendTo('#fixtures')
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()
      fakeENV.setup(context_asset_string: "account_1")
      @server = sinon.fakeServer.create()

    teardown: ->
      @container.remove()
      tz.restore(@snapshot)
      I18nStubber.popFrame()
      fakeENV.teardown()
      @server.restore()

  test 'should format release date with locale-appropriate format string', ->
    releaseDate = tz.parse('2100-07-04T00:00:00Z')

    tz.changeLocale(french, 'fr_FR', 'fr')
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

  test 'should function in three-state mode', ->
    @server.respondWith 'POST', "/api/v1/accounts/1/features/flags/differentiated_assignments", [200, {"Content-Type": "application/json"}, JSON.stringify(
      {"context_id":"1","context_type":"Account","feature":"differentiated_assignments","locking_account_id":null,"state": "on",
      "transitions":{"off":{"locked":false,"message":"wat?"},"allowed":{"locked":false,"message":"frd?"}},
      "locked":false,"hidden":false})]

    flag = new FeatureFlag({
      "feature": "differentiated_assignments",
      "applies_to": "Course",
      "root_opt_in": true,
      "beta": true,
      "development": false,
      "display_name": "Differentiated Assignments",
      "description": "Choose your own adventure!",
      "feature_flag": {
        "context_id": "1",
        "context_type": "Account",
        "feature": "differentiated_assignments",
        "locking_account_id": null,
        "state": "allowed",
        "transitions": {
          "off": {
            "locked": false,
            "message": "Fool! You'll kill us all!"
          },
          "on": {
            "locked": false
          }
        },
        "locked": false,
        "hidden": false
      }
    }, {parse: true})
    view = new FeatureFlagView el: @container, model: flag
    view.render()

    ok !view.$("#ff_off_differentiated_assignments").is(":checked")
    ok  view.$("#ff_allowed_differentiated_assignments").is(":checked")
    ok !view.$("#ff_on_differentiated_assignments").is(":checked")
    equal flag.state(), "allowed"

    view.$('#ff_on_differentiated_assignments').click()
    @server.respond()

    equal flag.state(), "on"
    deepEqual flag.transitions(), {"off":{"locked":false,"message":"wat?"},"allowed":{"locked":false,"message":"frd?"}}

  test 'should function in two-state mode', ->
    @server.respondWith 'POST', "/api/v1/accounts/1/features/flags/k12", [200, {"Content-Type": "application/json"}, JSON.stringify(
        {"context_id":"1","context_type":"Account","feature":"k12","locking_account_id":null,"state":"off",
        "transitions":{"on":{"locked":false},"allowed":{"locked":true}},"locked":false,"hidden":false})]

    flag = new FeatureFlag({
      "feature": "k12",
      "applies_to": "RootAccount",
      "root_opt_in": true,
      "beta": true,
      "display_name": "K-12 specific features",
      "description": "This makes everything big and blue.",
      "feature_flag": {
        "context_id": "1",
        "context_type": "Account",
        "feature": "k12",
        "locking_account_id": null,
        "state": "on",
        "transitions": {
          "off": {
            "locked": false
          },
          "allowed": {
            "locked": true
          }
        },
        "locked": false,
        "hidden": false
      }
    }, {parse: true})

    view = new FeatureFlagView el: @container, model: flag
    view.render()

    ok view.$("#ff_toggle_k12").is(":checked")
    equal flag.state(), "on"

    view.$('#ff_toggle_k12').click()
    @server.respond()

    equal flag.state(), "off"
    deepEqual flag.transitions(), {"on":{"locked":false},"allowed":{"locked":true}}
