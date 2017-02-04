define [
  'Backbone',
  'compiled/models/Conference',
  'compiled/views/conferences/ConferenceView',
  'jquery',
  'helpers/I18nStubber',
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, Conference, ConferenceView, $, I18nStubber, fakeENV) ->
  fixtures = $('#fixtures')
  conferenceView = (conferenceOpts = {}) ->
    conference = new Conference
          recordings: []
          user_settings: {}
          permissions: {close: true, create: true, delete: true, initiate: true, join: true, read: true, resume: false, update: true, edit: true}

    app = new ConferenceView
      model: conference

    app.$el.appendTo $('#fixtures')
    app.render()

  QUnit.module 'ConferenceView',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()

  test 'renders', ->
    view = conferenceView()
    ok view

  test 'delete calls screenreader', ->
    @stub(window, 'confirm').returns(true)
    ENV.context_asset_string = "course_1"
    server = sinon.fakeServer.create()
    server.respondWith('DELETE', '/api/v1/courses/1/conferences/1',
      [200, { 'Content-Type': 'application/json' }, JSON.stringify({
      "conference_type":"AdobeConnect",
      "context_code":"course_1",
      "context_id":1,
      "context_type":"Course",
      "join_url":"www.blah.com"})])

    @spy($, 'screenReaderFlashMessage')
    view = conferenceView()
    view.delete(jQuery.Event( "click" ))
    server.respond()
    equal $.screenReaderFlashMessage.callCount, 1
