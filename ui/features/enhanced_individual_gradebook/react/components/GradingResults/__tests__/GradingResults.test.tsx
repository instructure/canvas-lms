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
import {
  defaultStudentSubmissions,
  defaultAssignment,
  gradingResultsDefaultProps,
  defaultGradebookOptions,
} from './fixtures'
import {GRADEBOOK_SUBMISSION_COMMENTS} from '../../../../queries/Queries'
import {MockedProvider} from '@apollo/react-testing'
import {executeApiRequest} from '@canvas/util/apiRequest'
import {
  AssignmentConnection,
  GradebookUserSubmissionDetails,
} from 'features/enhanced_individual_gradebook/types'

jest.mock('@canvas/util/apiRequest', () => ({
  executeApiRequest: jest.fn(),
}))

const defaultMocks = (result = {data: {}}) => [
  {
    request: {
      query: GRADEBOOK_SUBMISSION_COMMENTS,
      variables: {},
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
    it('renders the correct final grade and late penalty labels when late is true', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission_late_penalty_label')).toHaveTextContent('Late Penalty')
      expect(getByTestId('late_penalty_final_grade_label')).toHaveTextContent('Final Grade')
    })

    it('renders the correct final grade and late penalty values when submission has not been graded and late', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
            enteredGrade: null,
            enteredScore: null,
            grade: null,
            score: null,
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission_late_penalty_value')).toHaveTextContent('0')
      expect(getByTestId('late_penalty_final_grade_value')).toHaveTextContent('-')
    })

    it('renders the correct final grade and late penalty values when submission has been graded and late', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
            deductedPoints: 20,
            score: 75,
            grade: '75',
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('submission_late_penalty_value')).toHaveTextContent('-20')
      expect(getByTestId('late_penalty_final_grade_value')).toHaveTextContent('75')
    })

    it('renders the entered grade instead of the grade with late penalty deductions in the grade input box', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...defaultStudentSubmissions,
            late: true,
            deductedPoints: 20,
            score: 75,
            grade: '75',
          },
        ],
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_input')).toHaveValue('95')
    })

    it('does not render final grade and penalty labels/values when late is false', () => {
      const {queryByTestId} = renderGradingResults(gradingResultsDefaultProps)
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
      expect(getByTestId('submission_details_grade_input')).toBeDisabled()
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
      expect(getByTestId('submission_details_grade_input')).not.toBeDisabled()
      expect(getByTestId('submission-details-submit-button')).not.toBeDisabled()
    })

    it('renders a message indicating that the current assignment is dropped when dropped is true', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        dropped: true,
      }
      const {getByTestId} = renderGradingResults(modifiedProps)
      expect(getByTestId('dropped-assignment-message')).toBeInTheDocument()
    })

    it('does not render a message indicating that the current assignment is dropped when dropped is false', () => {
      const modifiedProps = {
        ...gradingResultsDefaultProps,
        dropped: false,
      }
      const {queryByTestId} = renderGradingResults(modifiedProps)
      expect(queryByTestId('dropped-assignment-message')).not.toBeInTheDocument()
    })
  })
  describe('the assignment grading type is pass fail', () => {
    let modifiedDefaultStudentSubmissions: GradebookUserSubmissionDetails
    let modifiedDefaultAssignments: AssignmentConnection
    beforeEach(() => {
      modifiedDefaultStudentSubmissions = {
        ...defaultStudentSubmissions,
        enteredGrade: null,
        enteredScore: null,
        score: null,
        grade: null,
      }
      modifiedDefaultAssignments = {
        ...defaultAssignment,
        gradingType: 'pass_fail',
      }
    })
    it('renders Ungraded in both the submission detail modal and main page drop downs and a dash in the Out of Text', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Ungraded')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent(
        '- out of 10'
      )
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission_details_grade_select')).toHaveValue('Ungraded')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('- out of 10')
    })
    it('renders Complete in both the submission detail modal and main page drop downs and sets the max score in the Out of Text', () => {
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
        '10 out of 10'
      )
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission_details_grade_select')).toHaveValue('Complete')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('10 out of 10')
    })
    it('renders Incomplete in both the submission detail modal and main page drop downs and sets 0 in the Out of Text', () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [
          {
            ...modifiedDefaultStudentSubmissions,
            enteredGrade: 'incomplete',
            enteredScore: 0,
            score: 0,
            grade: 'incomplete',
          },
        ],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_select')).toHaveValue('Incomplete')
      expect(getByTestId('student_and_assignment_grade_out_of_text')).toHaveTextContent(
        '0 out of 10'
      )
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission_details_grade_select')).toHaveValue('Incomplete')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('0 out of 10')
    })
    it('renders Excused in both the submission detail modal and main page drop downs and sets the text Excused in the Out of Text', () => {
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
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission_details_grade_select')).toHaveValue('Excused')
      expect(getByTestId('submission_details_grade_out_of_text')).toHaveTextContent('Excused')
    })
    it('there is a grade submission api request when a pass fail option is selected in the main grade page and blurred', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId, getByText} = renderGradingResults(props)
      const gradeSelector = getByTestId('student_and_assignment_grade_select')
      userEvent.click(gradeSelector)
      userEvent.click(getByText('Complete'))
      userEvent.tab()
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          submission: {
            posted_grade: 'complete',
          },
        },
        method: 'PUT',
        path: 'testUrl',
      })
    })
    it('there is a grade submission api request when a pass fail option is selected in the submissions detail modal', async () => {
      const props = {
        ...gradingResultsDefaultProps,
        studentSubmissions: [modifiedDefaultStudentSubmissions],
        assignment: modifiedDefaultAssignments,
      }
      const {getByTestId, getByText} = renderGradingResults(props)
      userEvent.click(getByTestId('submission-details-button'))
      userEvent.click(getByTestId('submission_details_grade_select'))
      userEvent.click(getByText('Complete'))
      userEvent.click(getByTestId('submission-details-submit-button'))
      expect(executeApiRequest).toHaveBeenCalledWith({
        body: {
          submission: {
            posted_grade: 'complete',
          },
        },
        method: 'PUT',
        path: 'testUrl',
      })
    })
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
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_input')).toBeDisabled()
      expect(getByTestId('excuse_assignment_checkbox')).toBeDisabled()
    })
    it('grade input is not disabled when assignment is in a closed grading period and user is an admin', () => {
      ENV.current_user_roles = ['admin']
      const {getByTestId} = renderGradingResults(props)
      expect(getByTestId('student_and_assignment_grade_input')).toBeEnabled()
      expect(getByTestId('excuse_assignment_checkbox')).toBeEnabled()
    })
    it('submission details grade input and update grade button are disabled when assignment is in a closed grading period and user is not an admin', () => {
      ENV.current_user_roles = ['teacher']
      const {getByTestId} = renderGradingResults(props)
      userEvent.click(getByTestId('submission-details-button'))
      expect(getByTestId('submission-details-submit-button')).toBeDisabled()
      expect(getByTestId('submission_details_grade_input')).toBeDisabled()
    })
    it('submission details grade input and update grade button are not disabled when assignment is in a closed grading period and user is an admin', () => {
      ENV.current_user_roles = ['admin']
      const {getByTestId} = renderGradingResults(props)
      userEvent.click(getByTestId('submission-details-button'))
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
        'This assignment has been resubmitted since it was graded last.'
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
})
