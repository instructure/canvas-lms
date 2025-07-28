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

import userSettings from '@canvas/user-settings'
import SpeedGrader from '../speed_grader'

jest.mock('@canvas/user-settings')

describe('SpeedGrader getStudentNameAndGrade', () => {
  let windowJsonData

  beforeEach(() => {
    windowJsonData = {
      studentsWithSubmissions: [
        {
          index: 0,
          id: 4,
          name: 'Guy B. Studying',
          anonymous_name: 'Student 1',
          submission_state: 'not_graded',
        },
        {
          index: 1,
          id: 12,
          name: 'Sil E. Bus',
          anonymous_name: 'Student 2',
          submission_state: 'graded',
        },
      ],
    }

    window.jsonData = windowJsonData
    SpeedGrader.EG.currentStudent = window.jsonData.studentsWithSubmissions[0]
  })

  afterEach(() => {
    delete window.jsonData
    jest.clearAllMocks()
  })

  it('returns student name and submission status', () => {
    userSettings.get.mockReturnValue(false)
    const result = SpeedGrader.EG.getStudentNameAndGrade()
    expect(result).toBe('Guy B. Studying - not graded')
  })

  it('returns anonymous name and submission status when student names are hidden', () => {
    userSettings.get.mockReturnValue(true)
    const result = SpeedGrader.EG.getStudentNameAndGrade()
    expect(result).toBe('Student 1 - not graded')
  })

  it('returns name and status for non-current student', () => {
    userSettings.get.mockReturnValue(false)
    const student = window.jsonData.studentsWithSubmissions[1]
    const result = SpeedGrader.EG.getStudentNameAndGrade(student)
    expect(result).toBe('Sil E. Bus - graded')
  })
})
