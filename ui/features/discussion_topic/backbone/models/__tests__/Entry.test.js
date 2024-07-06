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

import Entry from '../Entry'
import fakeENV from '@canvas/test-utils/fakeENV'
import sinon from 'sinon'

describe('Entry', () => {
  let user_id, server, entry, setSpy

  beforeEach(() => {
    fakeENV.setup()
    user_id = 1
    server = sinon.fakeServer.create()
    global.ENV = {
      DISCUSSION: {
        CURRENT_USER: {id: user_id},
        DELETE_URL: 'discussions/:id/',
        PERMISSIONS: {
          CAN_ATTACH: true,
          CAN_MANAGE_OWN: true,
        },
        SPEEDGRADER_URL_TEMPLATE: 'speed_grader?assignment_id=1&student_id=%3Astudent_id',
      },
    }
    entry = new Entry({
      id: 1,
      message: 'a comment, wooper',
      user_id,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    server.restore()
  })

  test('should persist replies locally, and call provided onComplete callback', () => {
    server.respondWith([200, {}, ''])
    const replies = [
      new Entry({
        id: 2,
        message: 'a reply',
        parent_id: 1,
      }),
    ]
    entry.set('replies', replies)
    setSpy = sinon.spy(entry, 'set')
    const onCompleteCallback = sinon.spy()
    entry.sync('update', entry, {complete: onCompleteCallback})
    server.respond()
    expect(setSpy.calledWith('replies', [])).toBe(true)
    expect(setSpy.calledWith('replies', replies)).toBe(true)
    expect(onCompleteCallback.called).toBe(true)
  })

  test('speedgraderUrl replaces :student_id in SPEEDGRADER_URL_TEMPLATE with the user ID', () => {
    const studentEntry = new Entry({
      id: 2,
      message: 'a reply',
      parent_id: 1,
      user_id: 100,
    })

    expect(studentEntry.speedgraderUrl()).toBe('speed_grader?assignment_id=1&student_id=100')
  })

  test('recognizes current user as its original author', () => {
    const nonAuthorEntry = new Entry({
      id: 2,
      message: 'a reply',
      parent_id: 1,
      user_id: 100,
    })

    expect(nonAuthorEntry.isAuthorsEntry()).toBe(false)
    expect(entry.isAuthorsEntry()).toBe(true)
  })
})
