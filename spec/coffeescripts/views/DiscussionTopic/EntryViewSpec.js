/* eslint-disable qunit/resolve-async */
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

import $ from 'jquery'
import 'jquery-migrate'
import Entry from 'ui/features/discussion_topic/backbone/models/Entry'
import EntryView from 'ui/features/discussion_topic/backbone/views/EntryView'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'

QUnit.module('EntryView', {
  setup() {
    fakeENV.setup({
      DISCUSSION: {
        PERMISSIONS: {CAN_REPLY: true},
        CURRENT_USER: {},
        THREADED: true,
      },
    })
  },
  teardown() {
    fakeENV.teardown()
    $('#fixtures').empty()
  },
})

test('it should be accessible', assert => {
  const entry = new Entry({
    id: 1,
    message: 'hi',
  })
  $('#fixtures').append($('<div />').attr('id', 'e1'))
  const view = new EntryView({
    model: entry,
    el: '#e1',
  })
  view.render()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders', () => {
  const entry = new Entry({
    id: 1,
    message: 'hi',
  })
  $('#fixtures').append($('<div />').attr('id', 'e1'))
  const view = new EntryView({
    model: entry,
    el: '#e1',
  })
  view.render()
  ok(view)
})

test('should listen on model change:replies', () => {
  const entry = new Entry({
    id: 1,
    message: 'a comment, wooper',
  })
  const spy = sandbox.stub(EntryView.prototype, 'renderTree')
  const view = new EntryView({model: entry})
  entry.set('replies', [
    new Entry({
      id: 2,
      message: 'a reply',
      parent_id: 1,
    }),
  ])
  ok(spy.called, 'should renderTree when value is not empty')
  spy.reset()
  entry.set('replies', [])
  ok(!spy.called, 'should not renderTree when value is empty')
})

test('mark deleted and childless entries with css classes', () => {
  $('#fixtures').append($('<div />').attr('id', 'e1'))
  const entry = new Entry({
    id: 1,
    message: 'a comment, wooper',
    deleted: true,
    replies: [
      {
        id: 2,
        message: 'a reply',
        parent_id: 1,
        deleted: true,
      },
    ],
  })
  const view = new EntryView({
    model: entry,
    el: '#e1',
  })
  view.render()
  ok(view.$el.hasClass('no-replies'))
  ok(view.$el.hasClass('deleted'))
})

test('checks for deeply nested replies when marking childless entries', () => {
  $('#fixtures').append($('<div />').attr('id', 'e1'))
  const entry = new Entry({
    id: 1,
    message: 'a comment, wooper',
    deleted: true,
    replies: [
      {
        id: 2,
        message: 'a reply',
        parent_id: 1,
        deleted: true,
        replies: [
          {
            id: 3,
            message: 'another reply',
            parent_id: 2,
            deleted: true,
            replies: [],
          },
          {
            id: 4,
            message: 'not deleted',
            parent_id: 2,
          },
        ],
      },
    ],
  })
  const view = new EntryView({
    model: entry,
    el: '#e1',
  })
  view.render()
  ok(!view.$el.hasClass('no-replies'))
  ok(view.$el.hasClass('deleted'))
})
