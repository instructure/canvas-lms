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

import {resetTrayHeight, getTrayHeight} from '../trayUtils'

beforeEach(() => {
  jest.resetModules()
})

afterEach(() => {
  jest.restoreAllMocks()
})

describe('trayUtils', () => {
  describe('getTrayHeight', () => {
    it('defaults tray height to 100vh when the masquerade bar is not present', () => {
      resetTrayHeight()
      document.body.classList.remove('is-masquerading-or-student-view')
      expect(getTrayHeight()).toBe('100vh')
    })

    it('adjusts height by 50px when the masquerade bar is present', () => {
      resetTrayHeight()
      document.body.classList.add('is-masquerading-or-student-view')
      expect(getTrayHeight()).toBe('calc(100vh - 50px)')
    })

    it('only checks for the masquerade bar once', () => {
      resetTrayHeight()
      jest.spyOn(document, 'querySelector')
      getTrayHeight()
      getTrayHeight()
      getTrayHeight()
      expect(document.querySelector).toHaveBeenCalledTimes(1)
    })
  })
})
