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

import {waitFor} from '@testing-library/dom'
import {navigateToLastPage} from '../pageNavigation'
import {PAGE_SIZE} from '../constants'
import type {ModulePageNavigationDetail} from '../types.d'

describe('pageNavigation', () => {
  describe('navigateToLastPage', () => {
    let eventHandler: any
    beforeEach(() => {
      eventHandler = vi.fn()
      document.addEventListener('module-page-navigation', eventHandler)
    })
    afterEach(() => {
      document.removeEventListener('module-page-navigation', eventHandler)
    })
    it('calculates the correct last page number', async () => {
      // Test with an empty page
      expect(navigateToLastPage('module-0', 0)).toBe(1)
      await waitFor(() => {
        const eventDetail = eventHandler.mock.calls.at(-1)[0].detail as ModulePageNavigationDetail
        expect(eventDetail.moduleId).toBe('module-0')
        expect(eventDetail.pageNumber).toBe(1)
      })

      // Test with exactly one page
      expect(navigateToLastPage('module-1', PAGE_SIZE)).toBe(1)
      await waitFor(() => {
        const eventDetail = eventHandler.mock.calls.at(-1)[0].detail as ModulePageNavigationDetail
        expect(eventDetail.moduleId).toBe('module-1')
        expect(eventDetail.pageNumber).toBe(1)
      })

      // Test with exactly two pages
      expect(navigateToLastPage('module-2', PAGE_SIZE * 2)).toBe(2)
      await waitFor(() => {
        const eventDetail = eventHandler.mock.calls.at(-1)[0].detail as ModulePageNavigationDetail
        expect(eventDetail.moduleId).toBe('module-2')
        expect(eventDetail.pageNumber).toBe(2)
      })

      // Test with partial page
      expect(navigateToLastPage('module-3', PAGE_SIZE + 5)).toBe(2)
      await waitFor(() => {
        const eventDetail = eventHandler.mock.calls.at(-1)[0].detail as ModulePageNavigationDetail
        expect(eventDetail.moduleId).toBe('module-3')
        expect(eventDetail.pageNumber).toBe(2)
      })
    })
  })
})
