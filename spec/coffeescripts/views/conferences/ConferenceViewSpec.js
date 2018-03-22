/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Backbone from 'Backbone'
import Conference from 'compiled/models/Conference'
import ConferenceView from 'compiled/views/conferences/ConferenceView'
import $ from 'jquery'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import 'helpers/jquery.simulate'

const fixtures = $('#fixtures')
const conferenceView = function(conferenceOpts = {}) {
  const conference = new Conference({
    recordings: [],
    user_settings: {},
    permissions: {
      close: true,
      create: true,
      delete: true,
      initiate: true,
      join: true,
      read: true,
      resume: false,
      update: true,
      edit: true
    }
  })
  const app = new ConferenceView({model: conference})
  app.$el.appendTo($('#fixtures'))
  return app.render()
}

QUnit.module('ConferenceView', {
  setup() {
    fakeENV.setup()
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(conferenceView(), done, {a11yReport: true})
})

test('renders', () => {
  const view = conferenceView()
  ok(view)
})

test('delete calls screenreader', function() {
  this.stub(window, 'confirm').returns(true)
  ENV.context_asset_string = 'course_1'
  const server = sinon.fakeServer.create()
  server.respondWith('DELETE', '/api/v1/courses/1/conferences/1', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({
      conference_type: 'AdobeConnect',
      context_code: 'course_1',
      context_id: 1,
      context_type: 'Course',
      join_url: 'www.blah.com'
    })
  ])
  this.spy($, 'screenReaderFlashMessage')
  const view = conferenceView()
  view.delete(jQuery.Event('click'))
  server.respond()
  equal($.screenReaderFlashMessage.callCount, 1)
})
