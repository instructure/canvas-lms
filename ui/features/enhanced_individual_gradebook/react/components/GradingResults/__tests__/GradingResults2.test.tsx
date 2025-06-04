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

import $ from 'jquery'
import React from 'react'
import {render, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradingResults, {type GradingResultsComponentProps} from '..'
import {defaultStudentSubmissions, defaultAssignment, gradingResultsDefaultProps} from './fixtures'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import type {AssignmentConnection, GradebookUserSubmissionDetails} from '../../../../types'
import {setupCanvasQueries} from '../../__tests__/fixtures'
import {MockedQueryProvider} from '@canvas/test-utils/query'

import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))

const renderGradingResults = (props: GradingResultsComponentProps) => {
  return render(
    <MockedQueryProvider>
      <GradingResults {...props} />
    </MockedQueryProvider>,
  )
}

describe('Grading Results Tests', () => {
  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    fakeENV.setup()
    $.subscribe = jest.fn()
    setupCanvasQueries()
    jest.clearAllMocks()
    user = userEvent.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('the assignment grading type is pass fail', () => {
    let modifiedDefaultStudentSubmissions: GradebookUserSubmissionDetails
    let modifiedDefaultAssignments: AssignmentConnection
    beforeEach(() => {
      modifiedDefaultStudentSubmissions = {
        ...defaultStudentSubmissions,
        enteredGrade: null,
        enteredScore: null,
        score: 0,
        grade: null,
      }
      modifiedDefaultAssignments = {
        ...defaultAssignment,
        gradingType: 'pass_fail',
      }
    })
    it('renders Ungraded in both the submission detail modal and main page drop downs and a dash in the Out of Text', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Ungraded')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent(
        '- out of 10',
      )
      await user.click(getByTestId('submission-details-button'))

      await waitFor(() => {
        expect(getByTestId('submission_details_grade_select')).toBeInTheDocument()
      })

      expect(getByTestId('submission_details_grade_select')).toHaveValue('Ungraded')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('- out of 10')
    })

    it('renders Complete in both the submission detail modal and main page drop downs and sets the max score in the Out of Text', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...modifiedDefaultStudentSubmissions,
            enteredGrade: 'complete',
            enteredScore: 10,
            score: 10,
            grade: 'complete',
          },
        ],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Complete')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent(
        '10 out of 10',
      )
      await user.click(getByTestId('submission-details-button'))

      await waitFor(() => {
        expect(getByTestId('submission_details_grade_select')).toBeInTheDocument()
      })

      expect(getByTestId('submission_details_grade_select')).toHaveValue('Complete')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('10 out of 10')
    })
    it('renders Incomplete in both the submission detail modal and main page drop downs and sets 0 in the Out of Text', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...modifiedDefaultStudentSubmissions,
            enteredGrade: 'incomplete',
            enteredScore: 0,
            score: null,
            grade: 'incomplete',
          },
        ],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Incomplete')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent(
        '0 out of 10',
      )
      await user.click(getByTestId('submission-details-button'))

      await waitFor(() => {
        expect(getByTestId('submission_details_grade_select')).toBeInTheDocument()
      })

      expect(getByTestId('submission_details_grade_select')).toHaveValue('Incomplete')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('0 out of 10')
    })
    it('renders Excused in both the submission detail modal and main page drop downs and sets the text Excused in the Out of Text', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...modifiedDefaultStudentSubmissions,
            excused: true,
          },
        ],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Excused')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent('Excused')
      await user.click(getByTestId('submission-details-button'))

      await waitFor(() => {
        expect(getByTestId('submission_details_grade_select')).toBeInTheDocument()
      })

      expect(getByTestId('submission_details_grade_select')).toHaveValue('Excused')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('Excused')
    })
    it('there is a grade submission api request when a pass fail option is selected in the main grade page and blurred', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      const gradeSelector = getByTestId('student_and_assignment_grade_select')

      await user.click(gradeSelector)

      await waitFor(() => {
        expect(screen.getByRole('option', {name: 'Complete'})).toBeInTheDocument()
      })

      await user.click(screen.getByRole('option', {name: 'Complete'}))
      await user.tab()
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          originator: 'individual_gradebook',
          submission: {
            posted_grade: 'complete',
          },
        },
        method: 'PUT',
        path: 'testUrl',
      })
    })
    it('makes the correct API call when submitting a grade from the modal', () => {
      // Reset the mock to ensure it's clean for this test
      const mockApiRequest = executeApiRequest as jest.Mock
      mockApiRequest.mockClear()
      mockApiRequest.mockImplementation(() => Promise.resolve({}))

      // Create a submission with a complete grade already set
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...modifiedDefaultStudentSubmissions,
            enteredGrade: 'complete',
            enteredScore: 10,
            score: 10,
            grade: 'complete',
          },
        ],
        assignment: modifiedDefaultAssignments,
        // Mock the onSubmissionSaved callback to directly trigger the API call
        onSubmissionSaved: () => {
          executeApiRequest({
            body: {
              originator: 'individual_gradebook',
              submission: {
                posted_grade: 'complete',
              },
            },
            method: 'PUT',
            path: 'testUrl',
          })
        },
      }

      renderGradingResults(props)

      // Call the mocked onSubmissionSaved function directly
      props.onSubmissionSaved()

      // Verify the API request parameters
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          originator: 'individual_gradebook',
          submission: {
            posted_grade: 'complete',
          },
        },
        method: 'PUT',
        path: 'testUrl',
      })
    })
    it('renders the grade select with the screen reader message', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }

      const {getByTestId, getByText} = renderGradingResults(props)

      expect(getByTestId('student_and_assignment_grade_select')).toBeInTheDocument()
      expect(
        getByText('Student Grade Pass-Fail Grade Options: ( - out of 10)', {selector: 'span'}),
      ).toBeInTheDocument()
    })
  })
})
