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

import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook#loadTrayStudent', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gradebookGrid.gridSupport = {
      state: {
        getActiveLocation: () => ({region: 'body', cell: 0, row: 1}),
        setActiveLocation: jest.fn(),
      },
      helper: {
        commitCurrentEdit: jest.fn(),
      },
    }
    gradebook.students = {
      1100: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
      },
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
      },
      1102: {
        id: '1102',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
      },
    }
    jest
      .spyOn(gradebook, 'listRows')
      .mockReturnValue([1100, 1101, 1102].map(id => gradebook.students[id]))
    jest.spyOn(gradebook, 'updateRowAndRenderSubmissionTray').mockImplementation(() => {})
    jest.spyOn(gradebook, 'unloadSubmissionComments').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('changes the highlighted cell to the previous row when called with "previous"', () => {
    gradebook.loadTrayStudent('previous')
    expect(gradebook.gradebookGrid.gridSupport.state.setActiveLocation).toHaveBeenCalledWith(
      'body',
      {cell: 0, row: 0},
    )
  })

  it('updates the submission tray state when called with "previous"', () => {
    gradebook.loadTrayStudent('previous')

    const submissionTrayState = gradebook.getSubmissionTrayState()
    const fieldsToConsider = ['open', 'studentId']

    const actual = {}
    fieldsToConsider.forEach(field => {
      actual[field] = submissionTrayState[field]
    })

    const expectation = {open: true, studentId: '1100'}
    expect(actual).toEqual(expectation)
  })

  it('updates and renders the submission tray with the new student when called with "previous"', () => {
    gradebook.loadTrayStudent('previous')
    expect(gradebook.updateRowAndRenderSubmissionTray).toHaveBeenCalledWith('1100')
  })

  it('does not change the highlighted cell when called with "previous" while on the first row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 0})
    gradebook.loadTrayStudent('previous')
    expect(gradebook.gradebookGrid.gridSupport.state.setActiveLocation).not.toHaveBeenCalled()
  })

  it('does not update the submission tray state when called with "previous" while on the first row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 0})
    jest.spyOn(gradebook, 'setSubmissionTrayState').mockImplementation(() => {})
    gradebook.loadTrayStudent('previous')
    expect(gradebook.setSubmissionTrayState).not.toHaveBeenCalled()
  })

  it('does not update and render the submission tray when called with "previous" while on the first row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 0})
    gradebook.loadTrayStudent('previous')
    expect(gradebook.updateRowAndRenderSubmissionTray).not.toHaveBeenCalled()
  })

  it('changes the highlighted cell to the next row when called with "next"', () => {
    gradebook.loadTrayStudent('next')
    expect(gradebook.gradebookGrid.gridSupport.state.setActiveLocation).toHaveBeenCalledWith(
      'body',
      {cell: 0, row: 2},
    )
  })

  it('updates the submission tray state when called with "next"', () => {
    gradebook.loadTrayStudent('next')

    const submissionTrayState = gradebook.getSubmissionTrayState()
    const fieldsToConsider = ['open', 'studentId']

    const actual = {}
    fieldsToConsider.forEach(field => {
      actual[field] = submissionTrayState[field]
    })

    const expectation = {open: true, studentId: '1102'}
    expect(actual).toEqual(expectation)
  })

  it('updates and renders the submission tray with the new student when called with "next"', () => {
    gradebook.loadTrayStudent('next')
    expect(gradebook.updateRowAndRenderSubmissionTray).toHaveBeenCalledWith('1102')
  })

  it('does not change the highlighted cell when called with "next" while on the last row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 2})
    gradebook.loadTrayStudent('next')
    expect(gradebook.gradebookGrid.gridSupport.state.setActiveLocation).not.toHaveBeenCalled()
  })

  it('does not update the submission tray state when called with "next" while on the last row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 2})
    jest.spyOn(gradebook, 'setSubmissionTrayState').mockImplementation(() => {})
    gradebook.loadTrayStudent('next')
    expect(gradebook.setSubmissionTrayState).not.toHaveBeenCalled()
  })

  it('does not update and render the submission tray when called with "next" while on the last row', () => {
    jest
      .spyOn(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .mockReturnValue({region: 'body', cell: 0, row: 2})
    gradebook.loadTrayStudent('next')
    expect(gradebook.updateRowAndRenderSubmissionTray).not.toHaveBeenCalled()
  })
})
