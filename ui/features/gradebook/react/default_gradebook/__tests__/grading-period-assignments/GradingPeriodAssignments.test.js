/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {createGradebook, setFixtureHtml} from '../GradebookSpecHelper'

describe('Gradebook > Students', () => {
  let container
  let gradebook

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml(container)
  })

  afterEach(() => {
    gradebook.destroy()
    container.remove()
  })

  describe('#updateGradingPeriodAssignments()', () => {
    let gradingPeriodAssignments

    beforeEach(() => {
      gradebook = createGradebook()
      gradingPeriodAssignments = {
        1501: ['2301', '2303'],
        1502: ['2302', '2304'],
      }
    })

    test('stores the given grading period assignments', () => {
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      expect(gradebook.courseContent.gradingPeriodAssignments).toEqual(gradingPeriodAssignments)
    })

    test('sets the grading period assignments loaded status to true', () => {
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      expect(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded).toBe(true)
    })

    test('updates columns when the grid has rendered', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(true)
      jest.spyOn(gradebook, 'updateColumns')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      expect(gradebook.updateColumns).toHaveBeenCalledTimes(1)
    })

    test('updates columns after storing grading period assignments', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(true)
      jest.spyOn(gradebook, 'updateColumns').mockImplementation(() => {
        expect(gradebook.courseContent.gradingPeriodAssignments).toEqual(gradingPeriodAssignments)
      })
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
    })

    test('does not update columns when the grid has not yet rendered', () => {
      jest.spyOn(gradebook, '_gridHasRendered').mockReturnValue(false)
      jest.spyOn(gradebook, 'updateColumns')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      expect(gradebook.updateColumns).not.toHaveBeenCalled()
    })

    test('updates essential data load status', () => {
      jest.spyOn(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      expect(gradebook._updateEssentialDataLoaded).toHaveBeenCalledTimes(1)
    })

    test('updates essential data load status after updating the grading period assignments loaded status', () => {
      jest.spyOn(gradebook, '_updateEssentialDataLoaded').mockImplementation(() => {
        expect(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded).toBe(true)
      })
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
    })
  })
})
