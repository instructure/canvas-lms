/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import Subject from '../page_blurred'
import K from '../../constants'
import $ from 'jquery'
import 'jquery-migrate'

// Mock window.blur since jsdom doesn't implement it
Object.defineProperty(window, 'blur', {
  value: jest.fn(),
  writable: true,
})

describe('Quizzes::LogAuditing::EventTrackers::PageBlurred', () => {
  it('sets up the proper context in constructor', () => {
    const tracker = new Subject()
    expect(tracker.eventType).toBe(K.EVT_PAGE_BLURRED)
    expect(tracker.priority).toBe(K.EVT_PRIORITY_LOW)
  })

  it('captures page blur events', done => {
    const tracker = new Subject()
    const capture = jest.fn()
    tracker.install(capture)
    $(window).blur()

    setTimeout(() => {
      expect(capture).toHaveBeenCalled()
      done()
    })
  })

  it('does not send events if in iframe (for RCE focusing)', () => {
    const tracker = new Subject()
    const capture = jest.fn()
    tracker.install(capture)

    const iframe = $('<iframe>').appendTo('body').focus()
    $(window).blur()

    expect(capture).not.toHaveBeenCalled()
    iframe.remove()
  })
})
