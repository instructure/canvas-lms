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

import Entry from 'ui/features/discussion_topic/backbone/models/Entry'
import fakeENV from 'helpers/fakeENV'

QUnit.module('Entry', {
  setup() {
    fakeENV.setup()
    this.user_id = 1
    this.server = sinon.fakeServer.create()
    ENV.DISCUSSION = {
      CURRENT_USER: {id: this.user_id},
      DELETE_URL: 'discussions/:id/',
      PERMISSIONS: {
        CAN_ATTACH: true,
        CAN_MANAGE_OWN: true,
      },
      SPEEDGRADER_URL_TEMPLATE: 'speed_grader?assignment_id=1&student_id=%3Astudent_id',
    }
    this.entry = new Entry({
      id: 1,
      message: 'a comment, wooper',
      user_id: this.user_id,
    })
  },
  teardown() {
    fakeENV.teardown()
    return this.server.restore()
  },
})

test('should persist replies locally, and call provided onComplete callback', function () {
  this.server.respondWith([200, {}, ''])
  const replies = [
    new Entry({
      id: 2,
      message: 'a reply',
      parent_id: 1,
    }),
  ]
  this.entry.set('replies', replies)
  this.setSpy = sandbox.spy(this.entry, 'set')
  const onCompleteCallback = sinon.spy()
  this.entry.sync('update', this.entry, {complete: onCompleteCallback})
  this.server.respond()
  ok(this.setSpy.calledWith('replies', []))
  ok(this.setSpy.calledWith('replies', replies))
  ok(onCompleteCallback.called)
})

test('speedgraderUrl replaces :student_id in SPEEDGRADER_URL_TEMPLATE with the user ID', () => {
  const studentEntry = new Entry({
    id: 2,
    message: 'a reply',
    parent_id: 1,
    user_id: 100,
  })

  strictEqual(studentEntry.speedgraderUrl(), 'speed_grader?assignment_id=1&student_id=100')
})

test('recognizes current user as its original author', function () {
  const nonAuthorEntry = new Entry({
    id: 2,
    message: 'a reply',
    parent_id: 1,
    user_id: 100,
  })

  ok(!nonAuthorEntry.isAuthorsEntry())
  ok(this.entry.isAuthorsEntry())
})
