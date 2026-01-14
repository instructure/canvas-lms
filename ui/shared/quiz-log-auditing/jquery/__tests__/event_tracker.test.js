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

import EventTracker from '../event_tracker'
import $ from 'jquery'
import 'jquery-migrate'

class TestEventTracker extends EventTracker {
  eventType = 'test_event'

  install(deliveryCallback) {
    this.deliveryCallback = deliveryCallback
  }
}

describe('Quizzes::LogAuditing::EventTracker', () => {
  afterEach(() => {
    $(document).off()
  })

  describe('uniqueId', () => {
    it('generates unique IDs for each tracker instance', () => {
      const tracker1 = new TestEventTracker()
      const tracker2 = new TestEventTracker()

      // Each tracker gets a unique ID suffix
      expect(tracker1.uid).toContain('_')
      expect(tracker2.uid).toContain('_')
      expect(tracker1.uid).not.toBe(tracker2.uid)
    })
  })

  describe('throttle', () => {
    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('throttles callback when throttle option is set', () => {
      const tracker = new TestEventTracker()
      const callback = vi.fn()

      tracker.bind(document, 'click', callback, {throttle: 1000})

      // First click should fire immediately (leading: true)
      $(document).trigger('click')
      expect(callback).toHaveBeenCalledTimes(1)

      // Subsequent clicks within throttle window should be ignored
      $(document).trigger('click')
      $(document).trigger('click')
      expect(callback).toHaveBeenCalledTimes(1)

      // After throttle window, next click should fire
      vi.advanceTimersByTime(1000)
      $(document).trigger('click')
      expect(callback).toHaveBeenCalledTimes(2)

      tracker.uninstall()
    })

    it('does not throttle when throttle option is not set', () => {
      const tracker = new TestEventTracker()
      const callback = vi.fn()

      tracker.bind(document, 'click', callback)

      $(document).trigger('click')
      $(document).trigger('click')
      $(document).trigger('click')

      expect(callback).toHaveBeenCalledTimes(3)

      tracker.uninstall()
    })
  })

  describe('uninstall', () => {
    it('removes event bindings on uninstall', () => {
      const tracker = new TestEventTracker()
      const callback = vi.fn()

      tracker.bind(document, 'click', callback)
      $(document).trigger('click')
      expect(callback).toHaveBeenCalledTimes(1)

      tracker.uninstall()
      $(document).trigger('click')
      expect(callback).toHaveBeenCalledTimes(1)
    })
  })
})
