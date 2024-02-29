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

import Conference from 'ui/features/conferences/backbone/models/Conference'
import ConferenceView from 'ui/features/conferences/backbone/views/ConferenceView'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import '@canvas/jquery/jquery.simulate'

const conferenceView = function (conferenceOpts = {}) {
  if (!('id' in conferenceOpts)) conferenceOpts.id = null
  if (!('recordings' in conferenceOpts)) conferenceOpts.recordings = []
  if (!('user_settings' in conferenceOpts)) conferenceOpts.user_settings = {}
  const conference = new Conference({
    id: conferenceOpts.id,
    conference_type: 'AdobeConnect',
    context_code: 'course_1',
    context_id: 1,
    context_type: 'Course',
    join_url: 'www.blah.com',
    recordings: conferenceOpts.recordings,
    user_settings: conferenceOpts.user_settings,
    permissions: {
      close: true,
      create: true,
      delete: true,
      initiate: true,
      join: true,
      read: true,
      resume: false,
      update: true,
      edit: true,
      manage_recordings: true,
    },
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
  },
})

// eslint-disable-next-line qunit/resolve-async
test('it should be accessible', assert => {
  const done = assert.async()
  assertions.isAccessible(conferenceView(), done, {a11yReport: true})
})

test('renders', () => {
  const view = conferenceView()
  ok(view)
})

test('delete calls screenreader', () => {
  sandbox.stub(window, 'confirm').returns(true)
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
      join_url: 'www.blah.com',
    }),
  ])
  sandbox.spy($, 'screenReaderFlashMessage')
  const view = conferenceView()
  view.delete($.Event('click'))
  server.respond()
  equal($.screenReaderFlashMessage.callCount, 1)
  server.restore()
})

test('deleteRecordings calls screenreader', () => {
  sandbox.stub(window, 'confirm').returns(true)
  ENV.context_asset_string = 'course_1'
  const server = sinon.fakeServer.create()
  server.respondWith('POST', '/recording', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify({
      deleted: true,
    }),
  ])
  const big_blue_button_conference = {
    id: 1,
    recordings: [
      {
        recording_id: '954cc3',
        title: 'Conference',
        duration_minutes: 0,
        playback_url: null,
        playback_formats: [
          {
            type: 'statistics',
            url: 'www.blah.com',
            length: null,
          },
          {
            type: 'presentation',
            url: 'www.blah.com',
            length: 0,
            show_to_students: true,
          },
        ],
        created_at: 1518554650000,
      },
    ],
    user_settings: {
      record: true,
    },
  }
  sandbox.spy($, 'screenReaderFlashMessage')
  const view = conferenceView(big_blue_button_conference)
  $('div.ig-button[data-id="954cc3"]').children('a').trigger($.Event('click'))
  server.respond()
  equal($.screenReaderFlashMessage.callCount, 1)
  server.restore()
  ok(view)
})

test('renders adobe connect link', () => {
  ENV.context_asset_string = 'course_1'
  ENV.conference_type_details = [
    {
      name: 'Adobe Connect',
      type: 'AdobeConnect',
      settings: [],
    },
  ]
  const adobe_connect_conference = {
    id: 1,
    conference_type: 'AdobeConnect',
    context_code: 'course_1',
    context_id: 1,
    context_type: 'Course',
    playback_url: 'www.blah.com',
    join_url: 'www.blah.com',
    recordings: [
      {
        recording_id: '954cc3',
        title: 'Conference',
        playback_url: 'www.blah.com',
        duration_minutes: 0,
        playback_formats: [
          {
            type: 'statistics',
            url: 'www.blah.com',
            length: null,
          },
          {
            type: 'presentation',
            url: 'www.blah.com',
            length: 0,
          },
        ],
        created_at: 1518554650000,
      },
    ],
    user_settings: {
      record: true,
    },
  }
  conferenceView(adobe_connect_conference)
  equal($('#adobe-connect-playback-link').attr('href'), 'www.blah.com')
})
