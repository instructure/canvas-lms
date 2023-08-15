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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GradingResults, {GradingResultsComponentProps} from '..'
import {gradingResultsDefaultProps, defaultAssignment, defaultGradebookOptions} from './fixtures'
import {GRADEBOOK_SUBMISSION_COMMENTS} from '../../../../queries/Queries'
import {MockedProvider} from '@apollo/react-testing'

const defaultMocks = (result = {data: {}}) => [
  {
    request: {
      query: GRADEBOOK_SUBMISSION_COMMENTS,
      variables: {courseID: '1', submissionId: '1'},
    },
    result,
  },
]

const renderGradingResults = (props: GradingResultsComponentProps) => {
  return render(
    <MockedProvider mocks={defaultMocks()}>
      <GradingResults {...props} />
    </MockedProvider>
  )
}

describe('Grading Results Tests', () => {
  beforeEach(() => {
    $.subscribe = jest.fn()
  })
  describe('the submission is late', () => {
    let props: GradingResultsComponentProps
    beforeEach(() => {
      props = {
        ...gradingResultsDefaultProps,
        studentSubmissions:
          gradingResultsDefaultProps.studentSubmissions?.map(submission => ({
            ...submission,
            late: true,
          })) ?? undefined,
      }
    })

    it('renders the correct final grade and late penalty labels when late is true', () => {
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission_late_penalty_label')).toHaveTextContent('Late Penalty')
      expect(getByTestId('late_penalty_final_grade_label')).toHaveTextContent('Final Grade')
    })

    it('renders the correct final grade and late penalty values when submission has not been graded and late', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          props.studentSubmissions?.map(submission => ({
            ...submission,
            enteredGrade: null,
            enteredScore: null,
            grade: null,
            score: null,
          })) ?? undefined,
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('submission_late_penalty_value')).toHaveTextContent('0')
      expect(getByTestId('late_penalty_final_grade_value')).toHaveTextContent('-')
    })

    it('renders the correct final grade and late penalty values when submission has been graded and late', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          props.studentSubmissions?.map(submission => ({
            ...submission,
            deductedPoints: 20,
            score: 75,
            grade: '75',
          })) ?? undefined,
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('submission_late_penalty_value')).toHaveTextContent('-20')
      expect(getByTestId('late_penalty_final_grade_value')).toHaveTextContent('75')
    })

    it('renders the entered grade instead of the grade with late penalty deductions in the grade input box', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          props.studentSubmissions?.map(submission => ({
            ...submission,
            deductedPoints: 20,
            score: 75,
            grade: '75',
          })) ?? undefined,
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('student_and_assignment_grade_input')).toHaveValue('95')
    })

    it('does not render final grade and penalty labels/values when late is false', () => {
      const modifiedProps = {
        ...props,
        studentSubmissions:
          gradingResultsDefaultProps.studentSubmissions?.map(submission => ({
            ...submission,
            late: false,
          })) ?? undefined,
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('submission_late_penalty_label')).toBeNull()
      expect(queryByTestId('late_penalty_final_grade_label')).toBeNull()
      expect(queryByTestId('submission_late_penalty_values')).toBeNull()
      expect(queryByTestId('late_penalty_final_grade_values')).toBeNull()
    })

    it('renders the proxy submit button when the FF is enabled and submission types include online upload', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        gradebookOptions: {
          ...defaultGradebookOptions,
          proxySubmissionEnabled: true,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('proxy-submission-button')).toBeInTheDocument()
    })

    it('does not render the proxy submit button when the FF is disabled', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        proxySubmissionEnabled: false,
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('proxy-submission-button')).not.toBeInTheDocument()
    })

    it('does not render the proxy submit button when online upload is not a submission type', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
          submissionTypes: ['online_text_entry'],
        },
        gradebookOptions: {
          ...defaultGradebookOptions,
          proxySubmissionEnabled: true,
        },
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('proxy-submission-button')).not.toBeInTheDocument()
    })

    it('renders the proxy submit modal when the submit for student button is clicked', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
        },
        gradebookOptions: {
          ...defaultGradebookOptions,
          proxySubmissionEnabled: true,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      userEvent.click(getByTestId('proxy-submission-button'))
      expect(getByTestId('proxyInputFileDrop')).toBeInTheDocument()
    })

    it('disables the grade input when a moderated assignment has not posted grades', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
          moderatedGrading: true,
          gradesPublished: false,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('student_and_assignment_grade_input')).toBeDisabled()
    })

    it('enables the grade input when a moderated assignment has posted grades', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
          moderatedGrading: true,
          gradesPublished: true,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('student_and_assignment_grade_input')).not.toBeDisabled()
    })

    it('disables the submission details grade input and update grade button when moderated assignment grades have not been posted', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
          moderatedGrading: true,
          gradesPublished: false,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission-details-grade-input')).toBeDisabled()
      expect(getByTestId('submission-details-submit-button')).toBeDisabled()
    })

    it('enables the submission details grade input and update grade button when moderated assignment grades have been posted', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        assignment: {
          ...defaultAssignment,
          moderatedGrading: true,
          gradesPublished: true,
        },
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission-details-grade-input')).not.toBeDisabled()
      expect(getByTestId('submission-details-submit-button')).not.toBeDisabled()
    })
  })
})
