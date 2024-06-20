/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import Subject from '../page_focused'
import K from '../../constants'
import $ from 'jquery'
import sinon from 'sinon'

const capture = sinon.spy()
const tracker = new Subject()
tracker.install(capture)

describe('Quizzes::LogAuditing::EventTrackers::PageFocused', () => {
  afterEach(() => {
    sinon.restore()
  })

  it.skip('#constructor: it sets up the proper context', () => {
    expect(tracker.eventType).toEqual(K.EVT_PAGE_FOCUSED)
    expect(tracker.priority).toEqual(K.EVT_PRIORITY_LOW)
  })

  it.skip('capturing: it works', () => {
    $(window).focus()
    // it captures page focus
    expect(capture.called).toBeTruthy()
  })

  it.skip('capturing: it throttles captures', () => {
    $(window).focus()
    $(window).blur()
    $(window).focus()
    $(window).blur()
    $(window).focus()
    // it ignores rapidly repetitive focuses
    expect(capture.callCount).toEqual(1)
  })
})
