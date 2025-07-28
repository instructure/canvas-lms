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
import Entry from '../../models/Entry'
import EntryView from '../EntryView'
import fakeENV from '@canvas/test-utils/fakeENV'
import {isAccessible} from '@canvas/test-utils/jestAssertions'

describe('EntryView', () => {
  beforeEach(() => {
    fakeENV.setup({
      DISCUSSION: {
        PERMISSIONS: {CAN_REPLY: true},
        CURRENT_USER: {},
        THREADED: true,
      },
    })
    document.body.innerHTML = '<div id="fixtures"></div>'
  })

  afterEach(() => {
    fakeENV.teardown()
    $('#fixtures').empty()
  })

  // fails in Jest, passes in QUnit
  test.skip('it should be accessible', done => {
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
    isAccessible(view, done)
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
    expect(view).toBeDefined()
  })

  test('should only count non-deleted replies', () => {
    const entry = new Entry({
      id: 1,
      message: 'hi',
      replies: [
        {id: 2, message: 'hi', deleted: true},
        {id: 3, message: 'hi'},
      ],
    })
    const view = new EntryView({model: entry})
    const stats = view.countPosterity()
    expect(stats.total).toBe(1)
    expect(stats.unread).toBe(0)
  })

  // fails in Jest, passes in QUnit
  test.skip('should listen on model change: replies', () => {
    const entry = new Entry({
      id: 1,
      message: 'a comment, wooper',
    })
    const view = new EntryView({model: entry})
    const spy = jest.spyOn(view, 'renderTree')
    entry.set('replies', [new Entry({id: 2, message: 'a reply', parent_id: 1})])
    expect(spy).toHaveBeenCalled()
    spy.mockClear()
    entry.set('replies', [])
    expect(spy).not.toHaveBeenCalled()
  })

  test('mark deleted and childless entries with css classes', () => {
    $('#fixtures').append($('<div />').attr('id', 'e1'))
    const entry = new Entry({
      id: 1,
      message: 'a comment, wooper',
      deleted: true,
      replies: [{id: 2, message: 'a reply', parent_id: 1, deleted: true}],
    })
    const view = new EntryView({
      model: entry,
      el: '#e1',
    })
    view.render()
    expect(view.$el.hasClass('no-replies')).toBeTruthy()
    expect(view.$el.hasClass('deleted')).toBeTruthy()
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
            {id: 3, message: 'another reply', parent_id: 2, deleted: true, replies: []},
            {id: 4, message: 'not deleted', parent_id: 2},
          ],
        },
      ],
    })
    const view = new EntryView({
      model: entry,
      el: '#e1',
    })
    view.render()
    expect(view.$el.hasClass('no-replies')).toBeFalsy()
    expect(view.$el.hasClass('deleted')).toBeTruthy()
  })
})
