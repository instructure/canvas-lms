/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {addCorrelationIdToUrl} from '../urlHelpers'

describe('urlHelpers', () => {
  const mockLocationUrl = (url: string) => {
    window.history.pushState({}, '', url)
  }

  let replaceStateSpy: jest.SpyInstance

  beforeEach(() => {
    replaceStateSpy = jest.spyOn(window.history, 'replaceState')
  })

  afterEach(() => {
    replaceStateSpy.mockRestore()
  })

  describe('addCorrelationIdToUrl', () => {
    it('adds correlationId to URL when not present', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook')

      const correlationId = 'test-correlation-id-123'
      addCorrelationIdToUrl(correlationId)

      expect(replaceStateSpy).toHaveBeenCalledTimes(1)
      expect(replaceStateSpy).toHaveBeenCalledWith(
        {},
        '',
        '/courses/1/gradebook?cid=test-correlation-id-123',
      )
    })

    it('does not update if correlationId matches existing value', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook?cid=test-id')

      const correlationId = 'test-id'
      addCorrelationIdToUrl(correlationId)

      expect(replaceStateSpy).not.toHaveBeenCalled()
    })

    it('updates correlationId if it does not match existing value', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook?cid=old-id')

      const correlationId = 'new-id'
      addCorrelationIdToUrl(correlationId)

      expect(replaceStateSpy).toHaveBeenCalledTimes(1)
      expect(replaceStateSpy).toHaveBeenCalledWith({}, '', '/courses/1/gradebook?cid=new-id')
    })

    it('preserves existing query parameters', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook?foo=bar&baz=qux')

      const correlationId = 'test-id'
      addCorrelationIdToUrl(correlationId)

      expect(replaceStateSpy).toHaveBeenCalledTimes(1)
      const calledUrl = replaceStateSpy.mock.calls[0][2]
      expect(calledUrl).toContain('foo=bar')
      expect(calledUrl).toContain('baz=qux')
      expect(calledUrl).toContain('cid=test-id')
    })

    it('preserves URL hash', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook#section-123')

      const correlationId = 'test-id'
      addCorrelationIdToUrl(correlationId)

      expect(replaceStateSpy).toHaveBeenCalledTimes(1)
      expect(replaceStateSpy.mock.calls[0][2]).toContain('#section-123')
      expect(replaceStateSpy.mock.calls[0][2]).toContain('cid=test-id')
    })

    it('uses replaceState instead of pushState', () => {
      mockLocationUrl('http://localhost/courses/1/gradebook')

      const correlationId = 'test-id'
      addCorrelationIdToUrl(correlationId)

      // Verify replaceState was called (no new history entry)
      expect(replaceStateSpy).toHaveBeenCalledTimes(1)
    })
  })
})
