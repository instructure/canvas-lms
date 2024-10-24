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

import {showCourseNav, hideCourseNav} from '../toggleCourseNav'
import updateSubnavMenuToggle from '@canvas/courses/jquery/updateSubnavMenuToggle'

jest.mock('@canvas/courses/jquery/updateSubnavMenuToggle', () => jest.fn())

describe('toggleCourseNav', () => {
  describe('course nav menu is open', () => {
    beforeEach(() => {
      document.body.classList.add('course-menu-expanded')
      jest.clearAllMocks()
    })

    it('showCourseNav show do nothing', () => {
      showCourseNav()
      expect(document.body.classList).toContain('course-menu-expanded')
      expect(updateSubnavMenuToggle).not.toHaveBeenCalled()
    })

    it('hideCourseNav should hide course nav', () => {
      hideCourseNav()
      expect(document.body.classList).not.toContain('course-menu-expanded')
      expect(updateSubnavMenuToggle).toHaveBeenCalled()
    })
  })

  describe('course nav menu is closed', () => {
    beforeEach(() => {
      document.body.classList.remove('course-menu-expanded')
      jest.clearAllMocks()
    })

    it('showCourseNav should show course nav', () => {
      showCourseNav()
      expect(document.body.classList).toContain('course-menu-expanded')
      expect(updateSubnavMenuToggle).toHaveBeenCalled()
    })

    it('hideCourseNav should do nothing', () => {
      hideCourseNav()
      expect(document.body.classList).not.toContain('course-menu-expanded')
      expect(updateSubnavMenuToggle).not.toHaveBeenCalled()
    })
  })
})
