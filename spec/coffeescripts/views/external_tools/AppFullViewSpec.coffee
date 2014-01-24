define [
  'Backbone'
  'jquery'
  'compiled/views/ExternalTools/AppFullView'
  'helpers/assertions'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, $, AppFullView, assert, fakeENV) ->

  view = null
  server = null

  module "ExternalTools",

    setup: ->
      fakeENV.setup()
      server = sinon.fakeServer.create()
      server.respondWith("GET", /reviews/,
        [200, { "Content-Type": "application/json" }, JSON.stringify([
          { 
            "created":"Mar  5, 2013",
            "id":55,
            "user_name":"mkroening",
            "user_url":"https://twitter.com/mkroening",
            "user_avatar_url":"https://api.twitter.com/1/users/profile_image/mkroening",
            "tool_name":"YouTube",
            "rating":4,
            "comments":"Though I love the idea of searching and easily embedding video within a page.",
            "source_name":"LTI-Examples",
            "source_url":null 
          }
        ])])

      model = new Backbone.Model
        "name": "YouTube"
        "id": "youtube"
        "description": "Search publicly available YouTube videos."
        "extensions": [
          "editor_button"
          "resource_selection"
        ],
        "ratings_count": 2
        "comments_count": 1
        "avg_rating": 4.5
        "banner_url": "https://www.edu-apps.org/tools/youtube/banner.png"
        "logo_url": "https://www.edu-apps.org/tools/youtube/logo.png"
        "icon_url": "https://www.edu-apps.org/tools/youtube/icon.png"
        "config_url": "https://www.edu-apps.org/tools/youtube/config.xml"
        "any_key": true

      view = new AppFullView
        model: model
      server.respond()
      view.render()
      $('#fixtures').html view.$el

    teardown: ->
      fakeENV.teardown()
      server.restore()
      view.remove()

  test 'AppFullView: render', ->
    assert.isVisible view.$('.individual-app')
    equal $('.individual-app h2').text(), "YouTube",
      'App name appears as header'
    equal $('.reviews tr').size(), 1,
      'Reviews are shown'
