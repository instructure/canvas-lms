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

import $ from 'jquery'
import SetDefaultGradeDialog from '@canvas/grading/jquery/SetDefaultGradeDialog'
import SetDefaultGradeDialogManager from '../SetDefaultGradeDialogManager'
import AsyncComponents from '../../default_gradebook/AsyncComponents'

jest.mock('@canvas/grading/jquery/SetDefaultGradeDialog', () => {
  return jest.fn().mockImplementation(() => ({
    show: jest.fn(),
  }))
})

const createAssignmentProp = () => ({
  id: '1',
  grades_published: true,
  html_url: 'http://assignment_htmlUrl',
  invalid: false,
  muted: false,
  name: 'Assignment #1',
  omit_from_final_grade: false,
  points_possible: 13,
  submission_types: ['online_text_entry'],
  course_id: '42',
})

const createGetStudentsProp = () => _assignmentId => [
  {
    id: '11',
    name: 'Clark Kent',
    isInactive: false,
    submission: {
      score: 7,
      submittedAt: null,
    },
  },
  {
    id: '13',
    name: 'Barry Allen',
    isInactive: false,
    submission: {
      score: 8,
      submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)'),
    },
  },
  {
    id: '15',
    name: 'Bruce Wayne',
    isInactive: false,
    submission: {
      score: undefined,
      submittedAt: undefined,
    },
  },
]

describe('SetDefaultGradeDialogManager#isDialogEnabled', () => {
  it('returns true when submissions are loaded', () => {
    const manager = new SetDefaultGradeDialogManager(
      createAssignmentProp(),
      createGetStudentsProp(),
      'contextId',
      true,
      'selectedSection',
      false,
      true,
    )

    expect(manager.isDialogEnabled()).toBe(true)
  })

  it('returns false when submissions are not loaded', () => {
    const manager = new SetDefaultGradeDialogManager(
      createAssignmentProp(),
      createGetStudentsProp(),
      'contextId',
      true,
      'selectedSection',
      false,
      false,
    )

    expect(manager.isDialogEnabled()).toBe(false)
  })

  it('returns false when grades are not published', () => {
    const manager = new SetDefaultGradeDialogManager(
      {...createAssignmentProp(), grades_published: false},
      createGetStudentsProp(),
      'contextId',
      true,
      'selectedSection',
      false,
      true,
    )

    expect(manager.isDialogEnabled()).toBe(false)
  })
})

describe('SetDefaultGradeDialogManager#showDialog', () => {
  let flashErrorMock
  let loadSetDefaultGradeDialogMock

  const setupDialogManager = opts => {
    const assignment = {
      ...createAssignmentProp(),
      inClosedGradingPeriod: opts.inClosedGradingPeriod,
    }

    return new SetDefaultGradeDialogManager(
      assignment,
      createGetStudentsProp(),
      'contextId',
      true,
      'selectedSection',
      opts.isAdmin,
      true,
    )
  }

  beforeEach(() => {
    flashErrorMock = jest.spyOn($, 'flashError')
    loadSetDefaultGradeDialogMock = jest.spyOn(AsyncComponents, 'loadSetDefaultGradeDialog')
    loadSetDefaultGradeDialogMock.mockResolvedValue(SetDefaultGradeDialog)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows the SetDefaultGradeDialog when assignment is not in a closed grading period', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: false, isAdmin: false})
    await manager.showDialog()

    expect(SetDefaultGradeDialog).toHaveBeenCalled()
  })

  it('does not show an error when assignment is not in a closed grading period', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: false, isAdmin: false})
    await manager.showDialog()

    expect(flashErrorMock).not.toHaveBeenCalled()
  })

  it('shows the SetDefaultGradeDialog when assignment is in a closed grading period but isAdmin is true', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: true, isAdmin: true})
    await manager.showDialog()

    expect(SetDefaultGradeDialog).toHaveBeenCalled()
  })

  it('does not show an error when assignment is in a closed grading period but isAdmin is true', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: true, isAdmin: true})
    await manager.showDialog()

    expect(flashErrorMock).not.toHaveBeenCalled()
  })

  it('shows an error message when assignment is in a closed grading period and isAdmin is false', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: true, isAdmin: false})
    await manager.showDialog()

    expect(flashErrorMock).toHaveBeenCalledTimes(1)
  })

  it('does not show the SetDefaultGradeDialog when assignment is in a closed grading period and isAdmin is false', async () => {
    const manager = setupDialogManager({inClosedGradingPeriod: true, isAdmin: false})
    await manager.showDialog()

    expect(SetDefaultGradeDialog).not.toHaveBeenCalled()
  })
})
