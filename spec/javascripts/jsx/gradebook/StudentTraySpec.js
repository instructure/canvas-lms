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

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook#loadTrayStudent', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gradebookGrid.gridSupport = {
      state: {
        getActiveLocation: () => ({region: 'body', cell: 0, row: 1}),
        setActiveLocation: sinon.stub(),
      },
      helper: {
        commitCurrentEdit() {},
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
    sinon.stub(gradebook, 'listRows').returns([1100, 1101, 1102].map(id => gradebook.students[id]))
    sinon.stub(gradebook, 'updateRowAndRenderSubmissionTray')
    sinon.stub(gradebook, 'unloadSubmissionComments')
  })

  test('when called with "previous", changes the highlighted cell to the previous row', () => {
    gradebook.loadTrayStudent('previous')

    const expectation = ['body', {cell: 0, row: 0}]
    deepEqual(
      gradebook.gradebookGrid.gridSupport.state.setActiveLocation.firstCall.args,
      expectation
    )
  })

  test('when called with "previous", updates the submission tray state', () => {
    gradebook.loadTrayStudent('previous')

    const submissionTrayState = gradebook.getSubmissionTrayState()
    const fieldsToConsider = ['open', 'studentId']

    const actual = {}
    fieldsToConsider.forEach(field => {
      actual[field] = submissionTrayState[field]
    })

    const expectation = {open: true, studentId: '1100'}
    deepEqual(actual, expectation)
  })

  test('when called with "previous", updates and renders the submission tray with the new student', () => {
    gradebook.loadTrayStudent('previous')

    deepEqual(gradebook.updateRowAndRenderSubmissionTray.firstCall.args, ['1100'])
  })

  test('when called with "previous" while on the first row, does not change the highlighted cell', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 0})
    gradebook.loadTrayStudent('previous')

    strictEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.callCount, 0)
  })

  test('when called with "previous" while on the first row, does not update the submission tray state', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 0})
    sinon.stub(gradebook, 'setSubmissionTrayState')
    gradebook.loadTrayStudent('previous')

    strictEqual(gradebook.setSubmissionTrayState.callCount, 0)
  })

  test('when called with "previous" while on the first row, does not update and render the submission tray', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 0})
    gradebook.loadTrayStudent('previous')

    strictEqual(gradebook.updateRowAndRenderSubmissionTray.callCount, 0)
  })

  test('when called with "next", changes the highlighted cell to the next row', () => {
    gradebook.loadTrayStudent('next')

    const expectation = ['body', {cell: 0, row: 2}]
    deepEqual(
      gradebook.gradebookGrid.gridSupport.state.setActiveLocation.firstCall.args,
      expectation
    )
  })

  test('when called with "next", updates the submission tray state', () => {
    gradebook.loadTrayStudent('next')

    const submissionTrayState = gradebook.getSubmissionTrayState()
    const fieldsToConsider = ['open', 'studentId']

    const actual = {}
    fieldsToConsider.forEach(field => {
      actual[field] = submissionTrayState[field]
    })

    const expectation = {open: true, studentId: '1102'}
    deepEqual(actual, expectation)
  })

  test('when called with "next", updates and renders the submission tray with the new student', () => {
    gradebook.loadTrayStudent('next')

    deepEqual(gradebook.updateRowAndRenderSubmissionTray.firstCall.args, ['1102'])
  })

  test('when called with "next" while on the last row, does not change the highlighted cell', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 2})
    gradebook.loadTrayStudent('next')

    strictEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.callCount, 0)
  })

  test('when called with "next" while on the last row, does not update the submission tray state', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 2})
    sinon.stub(gradebook, 'setSubmissionTrayState')
    gradebook.loadTrayStudent('next')

    strictEqual(gradebook.setSubmissionTrayState.callCount, 0)
  })

  test('when called with "next" while on the last row, does not update and render the submission tray', () => {
    sinon
      .stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation')
      .returns({region: 'body', cell: 0, row: 2})
    gradebook.loadTrayStudent('next')

    strictEqual(gradebook.updateRowAndRenderSubmissionTray.callCount, 0)
  })
})
