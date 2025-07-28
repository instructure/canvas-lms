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

import 'jquery-migrate'
import {createGradebook} from './GradebookSpecHelper'
import {hideAggregateColumns} from '../GradebookGrid/Grid.utils'

describe('hideAggregateColumns', () => {
  const createTestGradebook = () => {
    const gradebook = createGradebook({
      all_grading_periods_totals: false,
    })
    gradebook.gradingPeriodSet = {id: '1', gradingPeriods: [{id: '701'}, {id: '702'}]}
    return gradebook
  }

  it('returns false if there are no grading periods', () => {
    const gradebook = createTestGradebook()
    gradebook.gradingPeriodSet = null
    expect(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId)).toBeFalsy()
  })

  it('returns false if there are no grading periods, even if isAllGradingPeriods is true', () => {
    const gradebook = createTestGradebook()
    gradebook.gradingPeriodSet = null
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    expect(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId)).toBeFalsy()
  })

  it('returns false if "All Grading Periods" is not selected', () => {
    const gradebook = createTestGradebook()
    gradebook.gradingPeriodId = '701'
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
    expect(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId)).toBeFalsy()
  })

  it('returns true if "All Grading Periods" is selected', () => {
    const gradebook = createTestGradebook()
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    expect(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId)).toBeTruthy()
  })

  it('returns false if "All Grading Periods" is selected and displayTotalsForAllGradingPeriods is enabled', () => {
    const gradebook = createTestGradebook()
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true
    expect(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId)).toBeFalsy()
  })
})

describe('listHiddenAssignments', () => {
  let gradebook
  let gradedAssignment
  let notGradedAssignment

  beforeEach(() => {
    gradedAssignment = {
      assignment_group: {position: 1},
      assignment_group_id: '1',
      grading_type: 'online_text_entry',
      id: '2301',
      name: 'graded assignment',
      position: 1,
      published: true,
    }
    notGradedAssignment = {
      assignment_group: {position: 2},
      assignment_group_id: '2',
      grading_type: 'not_graded',
      id: '2302',
      name: 'not graded assignment',
      position: 2,
      published: true,
    }
    const submissionsChunk = [
      {
        submissions: [
          {
            assignment_id: '2301',
            id: '2501',
            posted_at: null,
            score: 10,
            user_id: '1101',
            workflow_state: 'graded',
          },
          {
            assignment_id: '2302',
            id: '2502',
            posted_at: null,
            score: 9,
            user_id: '1101',
            workflow_state: 'graded',
          },
        ],
        user_id: '1101',
      },
    ]
    gradebook = createGradebook()
    gradebook.assignments = {
      2301: gradedAssignment,
      2302: notGradedAssignment,
    }
    gradebook.students = {
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
          user_id: '1101',
        },
        assignment_2302: {
          assignment_id: '2302',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
          user_id: '1101',
        },
      },
    }
    gradebook.gotSubmissionsChunk(submissionsChunk)
    gradebook.setAssignmentGroups([
      {
        id: '1',
        assignments: [gradedAssignment],
      },
      {
        id: '2',
        assignments: [notGradedAssignment],
      },
    ])
    gradebook.setAssignmentsLoaded()
    gradebook.setSubmissionsLoaded(true)
  })

  it('includes assignments when submission is postable', () => {
    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    expect(hiddenAssignments.find(assignment => assignment.id === gradedAssignment.id)).toBeTruthy()
  })

  it('excludes "not_graded" assignments even when submission is postable', () => {
    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    expect(
      hiddenAssignments.find(assignment => assignment.id === notGradedAssignment.id),
    ).toBeFalsy()
  })

  it('ignores assignments excluded by the current set of filters', () => {
    gradebook.setFilterColumnsBySetting('assignmentGroupId', '2')
    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    expect(hiddenAssignments.find(assignment => assignment.id === gradedAssignment.id)).toBeFalsy()
  })
})
