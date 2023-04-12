/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import SubmissionStateMap from '../SubmissionStateMap'
import type {Assignment, Student} from '../../../api.d'

describe('SubmissionStateMap', () => {
  const map = new SubmissionStateMap({
    hasGradingPeriods: false,
    isAdmin: false,
    selectedGradingPeriodID: '1',
  })

  const students = [
    {
      id: '1',
      name: 'student 1',
    },
    {
      id: '2',
      name: 'student 2',
    },
  ] as Student[]

  const assignmentMap = {
    '1': {
      id: '1',
      name: 'assignment 1',
    } as Assignment,
    '2': {
      id: '2',
      name: 'assignment 2',
    } as Assignment,
  }

  map.setup(students, assignmentMap)
  it('studentSubmissionMap is correct', () => {
    expect(map.studentSubmissionMap).toEqual({
      '1': {
        '1': {
          assignment_id: '1',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '1',
        },
        '2': {
          assignment_id: '2',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '1',
        },
      },
      '2': {
        '1': {
          assignment_id: '1',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '2',
        },
        '2': {
          assignment_id: '2',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '2',
        },
      },
    })
  })

  it('assignmentStudentSubmissionMap', () => {
    expect(map.assignmentStudentSubmissionMap).toEqual({
      '1': {
        '1': {
          assignment_id: '1',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '1',
        },
        '2': {
          assignment_id: '1',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '2',
        },
      },
      '2': {
        '1': {
          assignment_id: '2',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '1',
        },
        '2': {
          assignment_id: '2',
          excused: false,
          late: false,
          missing: false,
          seconds_late: 0,
          user_id: '2',
        },
      },
    })
  })

  it('submissionCellMap', () => {
    expect(map.submissionCellMap).toEqual({
      '1': {
        '1': {
          locked: true,
          hideGrade: true,
        },
        '2': {
          locked: true,
          hideGrade: true,
        },
      },
      '2': {
        '1': {
          locked: true,
          hideGrade: true,
        },
        '2': {
          locked: true,
          hideGrade: true,
        },
      },
    })
  })

  it('getSubmission', () => {
    expect(map.getSubmission('1', '1')).toEqual({
      assignment_id: '1',
      excused: false,
      late: false,
      missing: false,
      seconds_late: 0,
      user_id: '1',
    })
  })

  it('getSubmissionsByAssignment', () => {
    expect(map.getSubmissionsByAssignment('1')).toEqual([
      {
        assignment_id: '1',
        excused: false,
        late: false,
        missing: false,
        seconds_late: 0,
        user_id: '1',
      },
      {
        assignment_id: '1',
        excused: false,
        late: false,
        missing: false,
        seconds_late: 0,
        user_id: '2',
      },
    ])
  })

  it('getSubmissionsByStudentAndAssignmentIds', () => {
    expect(map.getSubmissionsByStudentAndAssignmentIds('1', ['1'])).toEqual([
      {
        assignment_id: '1',
        excused: false,
        late: false,
        missing: false,
        seconds_late: 0,
        user_id: '1',
      },
    ])
  })
})
