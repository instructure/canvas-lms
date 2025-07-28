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

import $ from 'jquery'
import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradingResults, {type GradingResultsComponentProps} from '..'
import {
  defaultStudentSubmissions,
  defaultAssignment,
  gradingResultsDefaultProps,
  checkpointedAssignment,
} from './fixtures'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'
import type {AssignmentConnection, GradebookUserSubmissionDetails} from '../../../../types'
import type {GradingType} from '../../../../../../api'
import {setupCanvasQueries} from '../../__tests__/fixtures'
import {MockedQueryProvider} from '@canvas/test-utils/query'

jest.mock('@canvas/do-fetch-api-effect/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))

import fakeENV from '@canvas/test-utils/fakeENV'

const renderGradingResults = (props: GradingResultsComponentProps) => {
  return render(
    <MockedQueryProvider>
      <GradingResults {...props} />
    </MockedQueryProvider>,
  )
}

describe('Grading Results Tests', () => {
  beforeEach(() => {
    fakeENV.setup()
    $.subscribe = jest.fn()
    setupCanvasQueries()
    jest.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('the assignment is in a closed grading period', () => {
    let props: GradingResultsComponentProps
    beforeEach(() => {
      props = {
        ...gradingResultsDefaultProps,
        assignment: gradingResultsDefaultProps.assignment && {
          ...gradingResultsDefaultProps.assignment,
          inClosedGradingPeriod: true,
        },
      }
    })
    it('grade input and excuse checkbox are disabled when assignment is in a closed grading period and user is not an admin', () => {
      ENV.current_user_roles = ['teacher']
      ENV.current_user_is_admin = false
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_input')).toBeDisabled()
      expect(getByTestId('excuse_assignment_checkbox')).toBeDisabled()
    })
    it('grade input is not disabled when assignment is in a closed grading period and user is an admin', () => {
      ENV.current_user_roles = ['admin']
      ENV.current_user_is_admin = true
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_input')).toBeEnabled()
      expect(getByTestId('excuse_assignment_checkbox')).toBeEnabled()
    })
    it('submission details grade input and update grade button are disabled when assignment is in a closed grading period and user is not an admin', async () => {
      ENV.current_user_roles = ['teacher']
      ENV.current_user_is_admin = false
      const {getByTestId} = renderGradingResults(props)
      await userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission-details-submit-button')).toBeDisabled()
      expect(getByTestId('submission_details_grade_input')).toBeDisabled()
    })
    it('submission details grade input and update grade button are not disabled when assignment is in a closed grading period and user is an admin', async () => {
      ENV.current_user_roles = ['admin']
      ENV.current_user_is_admin = true
      const {getByTestId} = renderGradingResults(props)
      await userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission-details-submit-button')).toBeEnabled()
      expect(getByTestId('submission_details_grade_input')).not.toBeDisabled()
    })
  })
  describe('the submission is resubmitted', () => {
    let props: GradingResultsComponentProps
    beforeEach(() => {
      props = {
        ...gradingResultsDefaultProps,
        studentSubmissions:
          gradingResultsDefaultProps.studentSubmissions?.map(submission => ({
            ...submission,
            gradeMatchesCurrentSubmission: false,
          })) ?? undefined,
      }
    })
    it('renders the assignment has been resubmitted text', () => {
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('resubmitted_assignment_label')).toHaveTextContent(
        'This assignment has been resubmitted since it was graded last.',
      )
    })
    it('does not render the assignment has been resubmitted text', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          props.studentSubmissions?.map(submission => ({
            ...submission,
            gradeMatchesCurrentSubmission: true,
          })) ?? undefined,
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('resubmitted_assignment_label')).toBeNull()
    })
    it('does not render the assignment has been resubmitted text when assignment has not been graded', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          props.studentSubmissions?.map(submission => ({
            ...submission,
            gradeMatchesCurrentSubmission: null,
          })) ?? undefined,
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('resubmitted_assignment_label')).toBeNull()
    })
  })
  describe('checkpoints', () => {
    it('renders the grade inputs with the screen reader message when the grading type is points', () => {
      const props = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...checkpointedAssignment,
        },
      }

      const {getByTestId, getByText} = renderGradingResults(props)

      expect(getByTestId('student_and_reply_to_topic_assignment_grade_input')).toBeInTheDocument()
      expect(getByTestId('student_and_reply_to_entry_assignment_grade_input')).toBeInTheDocument()
      expect(getByTestId('student_and_assignment_grade_input')).toBeInTheDocument()

      expect(getByText('Reply to Topic: (out of 5)', {selector: 'span'})).toBeInTheDocument()
      expect(getByText('Required Replies: (out of 15)', {selector: 'span'})).toBeInTheDocument()
      expect(getByText('Total: (out of 20)', {selector: 'span'})).toBeInTheDocument()
    })

    it('renders the grade inputs with screen reader message when the grading type is pass fail', () => {
      const props = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...checkpointedAssignment,
          gradingType: 'pass_fail' as GradingType,
        },
      }

      if (!props.studentSubmissions?.[0]) {
        throw new Error('studentSubmissions is required')
      }
      props.studentSubmissions[0].score = null
      props.studentSubmissions[0].enteredScore = null
      props.studentSubmissions[0].enteredGrade = ''

      const {getByTestId, getByText} = renderGradingResults(props)

      expect(getByTestId('student_and_reply_to_topic_assignment_grade_select')).toBeInTheDocument()
      expect(getByTestId('student_and_reply_to_entry_assignment_grade_select')).toBeInTheDocument()
      expect(getByTestId('student_and_assignment_grade_select')).toBeInTheDocument()

      expect(getByText('Reply to Topic: ( - out of 5)', {selector: 'span'})).toBeInTheDocument()
      expect(getByText('Required Replies: ( - out of 15)', {selector: 'span'})).toBeInTheDocument()
      expect(getByText('Total: ( - out of 20)', {selector: 'span'})).toBeInTheDocument()
    })
  })
})
