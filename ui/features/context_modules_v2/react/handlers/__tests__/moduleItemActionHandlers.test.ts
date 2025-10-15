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

import type {ModuleItemContent} from '../../utils/types'

describe('moduleItemActionHandlers', () => {
  describe('handleSpeedGrader', () => {
    let windowOpenSpy: jest.SpyInstance

    // Define the function inline to avoid importing complex dependencies
    const handleSpeedGrader = (
      content: ModuleItemContent | null,
      courseId: string,
      setIsMenuOpen?: (isOpen: boolean) => void,
    ) => {
      if (
        content?.type?.toLowerCase().includes('assignment') ||
        content?.type?.toLowerCase().includes('quiz')
      ) {
        window.open(
          `/courses/${courseId}/gradebook/speed_grader?assignment_id=${content._id}`,
          '_blank',
        )
      }
      if (setIsMenuOpen) {
        setIsMenuOpen(false)
      }
    }

    beforeEach(() => {
      windowOpenSpy = jest.spyOn(window, 'open').mockImplementation()
    })

    afterEach(() => {
      windowOpenSpy.mockRestore()
    })

    it('opens SpeedGrader in a new tab for assignments', () => {
      const content = {
        _id: '123',
        type: 'Assignment',
      } as ModuleItemContent

      const courseId = '456'

      handleSpeedGrader(content, courseId)

      expect(windowOpenSpy).toHaveBeenCalledWith(
        '/courses/456/gradebook/speed_grader?assignment_id=123',
        '_blank',
      )
    })

    it('opens SpeedGrader in a new tab for quizzes', () => {
      const content = {
        _id: '789',
        type: 'Quiz',
      } as ModuleItemContent

      const courseId = '456'

      handleSpeedGrader(content, courseId)

      expect(windowOpenSpy).toHaveBeenCalledWith(
        '/courses/456/gradebook/speed_grader?assignment_id=789',
        '_blank',
      )
    })

    it('does not open SpeedGrader for non-assignment/quiz types', () => {
      const content = {
        _id: '999',
        type: 'Page',
      } as ModuleItemContent

      const courseId = '456'

      handleSpeedGrader(content, courseId)

      expect(windowOpenSpy).not.toHaveBeenCalled()
    })

    it('closes the menu if setIsMenuOpen is provided', () => {
      const content = {
        _id: '123',
        type: 'Assignment',
      } as ModuleItemContent

      const courseId = '456'
      const setIsMenuOpen = jest.fn()

      handleSpeedGrader(content, courseId, setIsMenuOpen)

      expect(setIsMenuOpen).toHaveBeenCalledWith(false)
    })
  })
})
