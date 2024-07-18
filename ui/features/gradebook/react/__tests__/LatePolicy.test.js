/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createGradebook} from '../default_gradebook/__tests__/GradebookSpecHelper'
import LatePolicyApplicator from '../LatePolicyApplicator'

describe('Gradebook#setLatePolicy', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  it('sets the late policy state', () => {
    const latePolicy = {lateSubmissionInterval: 'day'}
    gradebook.setLatePolicy(latePolicy)
    expect(gradebook.courseContent.latePolicy).toEqual(latePolicy)
  })
})

describe('Gradebook#applyLatePolicy', () => {
  let gradingStandard,
    gradebook,
    latePolicyApplicator,
    submission1,
    submission2,
    submission3,
    submission4

  beforeEach(() => {
    gradingStandard = [['A', 0]]
    gradebook = createGradebook({grading_standard: gradingStandard})
    gradebook.gradingPeriodSet = {
      gradingPeriods: [
        {id: 100, isClosed: true},
        {id: 101, isClosed: false},
      ],
    }
    latePolicyApplicator = jest
      .spyOn(LatePolicyApplicator, 'processSubmission')
      .mockReturnValue(true)

    submission1 = {
      user_id: 10,
      assignment_id: 'assignment_1',
      grading_period_id: null,
    }

    submission2 = {
      user_id: 10,
      assignment_id: 'assignment_2',
      grading_period_id: 100,
    }

    submission3 = {
      user_id: 11,
      assignment_id: 'assignment_2',
      grading_period_id: 101,
    }

    submission4 = {
      user_id: 12,
      assignment_id: 'assignment_1',
      grading_period_id: null,
    }

    gradebook.assignments = {
      assignment_1: 'assignment1value',
      assignment_2: 'assignment2value',
    }
    gradebook.students = {
      10: {
        assignment_1: submission1,
        assignment_2: submission2,
      },
      11: {
        assignment_2: submission3,
      },
      12: {
        assignment_1: submission4,
        isConcluded: true,
      },
    }
    gradebook.courseContent.latePolicy = 'latepolicy'
  })

  it('skips submissions for which assignments are not loaded', () => {
    gradebook.assignments = {assignment_2: 'assignment2value'}
    gradebook.applyLatePolicy()
    expect(latePolicyApplicator).not.toHaveBeenCalledWith(
      submission1,
      'assignment1value',
      gradingStandard,
      'latepolicy'
    )
  })

  it('does not affect submissions in closed grading periods', () => {
    gradebook.applyLatePolicy()
    expect(latePolicyApplicator).not.toHaveBeenCalledWith(
      submission2,
      'assignment2value',
      gradingStandard,
      'latepolicy'
    )
  })

  it('does not grade submissions for concluded students', () => {
    const calculateStudentGrade = jest.spyOn(gradebook, 'calculateStudentGrade')
    gradebook.applyLatePolicy()
    const gradesCalculated = calculateStudentGrade.mock.calls.some(
      call => call[0] === gradebook.students[12]
    )
    expect(gradesCalculated).toBe(false)
    calculateStudentGrade.mockRestore()
  })

  it('affects submissions that are not in a grading period', () => {
    gradebook.applyLatePolicy()
    expect(latePolicyApplicator).toHaveBeenCalledWith(
      submission1,
      'assignment1value',
      gradingStandard,
      'latepolicy'
    )
  })

  it('affects submissions that are in not-closed grading periods', () => {
    gradebook.applyLatePolicy()
    expect(latePolicyApplicator).toHaveBeenCalledWith(
      submission3,
      'assignment2value',
      gradingStandard,
      'latepolicy'
    )
  })
})
