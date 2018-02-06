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
  'Backbone',
  'compiled/models/Conference',
  'compiled/views/conferences/ConferenceView',
  'jquery',
  'helpers/I18nStubber',
  'helpers/fakeENV'
  'helpers/assertions'
  'helpers/jquery.simulate'
], (Backbone, Conference, ConferenceView, $, I18nStubber, fakeENV, assertions) ->
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

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible conferenceView(), done, {'a11yReport': true}

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
