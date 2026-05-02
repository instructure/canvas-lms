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
import AssignmentInformation from '../index'
import type {AssignmentInformationComponentProps} from '../index'
import type {SubmissionConnection} from '../../../../types'
import {assignmentInfoDefaultProps, defaultAssignment} from './fixtures'

const mockShow = vi.fn()
vi.mock('@canvas/assignment-posting-policy-tray', () => ({
  default: React.forwardRef((_props: object, ref: React.Ref<{show: () => void}>) => {
    React.useImperativeHandle(ref, () => ({show: mockShow}))
    return <div data-testid="assignment-posting-policy-tray" />
  }),
}))

describe('Assignment Information Tests', () => {
  beforeEach(() => {
    $.subscribe = vi.fn()
    mockShow.mockClear()
  })
  const renderAssignmentInformation = (props: AssignmentInformationComponentProps) => {
    return render(<AssignmentInformation {...props} />)
  }

  it('displayed default text when an assignment has not been selected', () => {
    const props = {...assignmentInfoDefaultProps, assignment: undefined}
    const {getByText} = renderAssignmentInformation(props)
    expect(
      getByText('Select an assignment to view additional information here.'),
    ).toBeInTheDocument()
  })

  it('displays the assignment name', () => {
    const {name = ''} = assignmentInfoDefaultProps.assignment ?? {}
    const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
    const assignmentNameNode = getByTestId('assignment-information-name')
    expect(assignmentNameNode).toHaveAttribute(
      'href',
      assignmentInfoDefaultProps.assignment?.htmlUrl,
    )
    expect(assignmentNameNode).toHaveTextContent(name)
  })

  it('displays the assignment speedgrader link', () => {
    const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
    const speedGraderUrl = '/courses/1/gradebook/speed_grader?assignment_id=1'
    const speedGraderUrlNode = getByTestId('assignment-speedgrader-link')
    expect(speedGraderUrlNode).toHaveAttribute('href', speedGraderUrl)
    expect(speedGraderUrlNode).toHaveTextContent('See this assignment in speedgrader')
  })

  it("displays the assignment's submission types", () => {
    const {getByTestId} = renderAssignmentInformation({...assignmentInfoDefaultProps})
    expect(getByTestId('assignment-submission-info')).toHaveTextContent('Online text entry')
    expect(getByTestId('assignment-submission-info')).toHaveTextContent('Online upload')
  })

  it('displays peer review submission type correctly', () => {
    const props = {
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        submissionTypes: ['peer_review'],
      },
    }
    const {getByTestId} = renderAssignmentInformation(props)
    expect(getByTestId('assignment-submission-info')).toHaveTextContent('Peer review')
  })

  it('does not display the message students who button when the selected assignment is anonymous', () => {
    const {queryByTestId} = renderAssignmentInformation({
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        anonymizeStudents: true,
      },
    })
    expect(queryByTestId('message-students-who-button')).toBeNull()
  })

  it('disables the default grade button when a moderated assignment is selected and has not been published', () => {
    const props = {
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        moderatedGrading: true,
        gradesPublished: false,
      },
    }
    const {getByTestId} = renderAssignmentInformation(props)
    expect(getByTestId('default-grade-button')).toBeDisabled()
  })

  it('enables the default grade button when a moderated assignment is selected and has been published', () => {
    const props = {
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        moderatedGrading: true,
        gradesPublished: true,
      },
    }
    const {getByTestId} = renderAssignmentInformation(props)
    expect(getByTestId('default-grade-button')).not.toBeDisabled()
  })

  it('disables Curve Grades Button if Assignment has checkpoints', () => {
    const props = {
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        checkpoints: [
          {
            dueAt: '2024-09-06T23:59:00-06:00',
            lockAt: '2024-09-06T23:59:00-06:00',
            name: 'Discussion 1',
            pointsPossible: 15,
            tag: 'reply_to_topic',
            unlockAt: '2024-09-03T00:00:00-06:00',
          },
        ],
      },
    }
    const {getByTestId} = renderAssignmentInformation(props)
    expect(getByTestId('curve-grades-button')).toBeDisabled()
  })

  it('enables Curve Grades Button if Assignment checkpoints is empty', () => {
    const props = {
      ...assignmentInfoDefaultProps,
      assignment: {
        ...defaultAssignment,
        checkpoints: [],
      },
    }
    const {getByTestId} = renderAssignmentInformation(props)
    expect(getByTestId('curve-grades-button')).toBeEnabled()
  })

  describe('assignment score details table', () => {
    const makeSubmission = (overrides: {
      id: string
      score: number | null
      userId: string
    }): SubmissionConnection => ({
      assignmentId: '1',
      redoRequest: false,
      submittedAt: null,
      state: 'graded',
      ...overrides,
    })

    it('shows "No graded submissions" for High and Low Score when all submissions are ungraded', () => {
      const props = {
        ...assignmentInfoDefaultProps,
        submissions: [
          makeSubmission({id: '1', score: null, userId: '1'}),
          makeSubmission({id: '2', score: null, userId: '2'}),
        ],
      }
      const {getByTestId} = renderAssignmentInformation(props)
      expect(getByTestId('assignment-max')).toHaveTextContent('No graded submissions')
      expect(getByTestId('assignment-min')).toHaveTextContent('No graded submissions')
    })

    it('excludes null scores and uses only numeric scores for High, Low, and Average', () => {
      const props = {
        ...assignmentInfoDefaultProps,
        submissions: [
          makeSubmission({id: '1', score: 8, userId: '1'}),
          makeSubmission({id: '2', score: null, userId: '2'}),
          makeSubmission({id: '3', score: 5, userId: '3'}),
        ],
      }
      const {getByTestId} = renderAssignmentInformation(props)
      expect(getByTestId('assignment-max')).toHaveTextContent('8')
      expect(getByTestId('assignment-min')).toHaveTextContent('5')
      expect(getByTestId('assignment-average')).toHaveTextContent('6.5')
    })

    it('includes a score of 0 in High and Low Score calculations', () => {
      const props = {
        ...assignmentInfoDefaultProps,
        submissions: [
          makeSubmission({id: '1', score: 10, userId: '1'}),
          makeSubmission({id: '2', score: 0, userId: '2'}),
          makeSubmission({id: '3', score: null, userId: '3'}),
        ],
      }
      const {getByTestId} = renderAssignmentInformation(props)
      expect(getByTestId('assignment-max')).toHaveTextContent('10')
      expect(getByTestId('assignment-min')).toHaveTextContent('0')
    })
  })

  describe('assignment in closed grading period', () => {
    let props: AssignmentInformationComponentProps
    beforeEach(() => {
      props = {
        ...assignmentInfoDefaultProps,
        assignment: {
          ...defaultAssignment,
          inClosedGradingPeriod: true,
        },
      }
    })

    it('displays warning for default grade and curve grades when assignment is in a closed grading period and user is not an admin', () => {
      ENV.current_user_is_admin = false
      ENV.current_user_roles = ['teacher']
      const {queryByTestId} = renderAssignmentInformation(props)
      expect(queryByTestId('default-grade-warning')).not.toBeNull()
      expect(queryByTestId('curve-grade-warning')).not.toBeNull()
    })

    it('does not display warning and disables buttons for default grade and curve grades when assignment is in a closed grading period and user is an admin', () => {
      ENV.current_user_is_admin = true
      ENV.current_user_roles = ['admin']
      const {queryByTestId} = renderAssignmentInformation(props)
      expect(queryByTestId('default-grade-warning')).toBeNull()
      expect(queryByTestId('curve-grade-warning')).toBeNull()
    })

    it('disables buttons for default grade and curve grades when assignment is in a closed grading period and user is not an admin', () => {
      ENV.current_user_is_admin = false
      ENV.current_user_roles = ['teacher']
      const {getByTestId} = renderAssignmentInformation(props)
      const defaultButton = getByTestId('default-grade-button')
      const curveButton = getByTestId('curve-grades-button')
      expect(defaultButton).toBeDisabled()
      expect(curveButton).toBeDisabled()
    })

    it('does not disable buttons for default grade and curve grades when assignment is in a closed grading period and user is an admin', () => {
      ENV.current_user_is_admin = true
      ENV.current_user_roles = ['admin']
      const {getByTestId} = renderAssignmentInformation(props)
      const defaultButton = getByTestId('default-grade-button')
      const curveButton = getByTestId('curve-grades-button')
      expect(defaultButton).toBeEnabled()
      expect(curveButton).toBeEnabled()
    })
  })

  describe('Grade Post Policy button', () => {
    it('renders when an assignment is selected', () => {
      const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
      expect(getByTestId('grade-post-policy-button')).toBeInTheDocument()
    })

    it('does not render when no assignment is selected', () => {
      const {queryByTestId} = renderAssignmentInformation({
        ...assignmentInfoDefaultProps,
        assignment: undefined,
      })
      expect(queryByTestId('grade-post-policy-button')).toBeNull()
    })

    it('opens the posting policy tray when clicked', async () => {
      const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
      await userEvent.click(getByTestId('grade-post-policy-button'))
      expect(getByTestId('assignment-posting-policy-tray')).toBeInTheDocument()
    })

    it('reflects updated postManually state on subsequent tray opens', async () => {
      const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
      await userEvent.click(getByTestId('grade-post-policy-button'))
      expect(mockShow).toHaveBeenCalledWith(
        expect.objectContaining({assignment: expect.objectContaining({postManually: false})}),
      )

      mockShow.mock.calls[0][0].onAssignmentPostPolicyUpdated({
        assignmentId: '1',
        postManually: true,
      })

      await userEvent.click(getByTestId('grade-post-policy-button'))
      expect(mockShow).toHaveBeenLastCalledWith(
        expect.objectContaining({assignment: expect.objectContaining({postManually: true})}),
      )
    })

    it('resets postManually when a different assignment is selected', async () => {
      const {getByTestId, rerender} = renderAssignmentInformation(assignmentInfoDefaultProps)
      await userEvent.click(getByTestId('grade-post-policy-button'))

      mockShow.mock.calls[0][0].onAssignmentPostPolicyUpdated({
        assignmentId: '1',
        postManually: true,
      })

      rerender(
        <AssignmentInformation
          {...assignmentInfoDefaultProps}
          assignment={{...defaultAssignment, id: '2', postManually: false}}
        />,
      )

      await userEvent.click(getByTestId('grade-post-policy-button'))
      expect(mockShow).toHaveBeenLastCalledWith(
        expect.objectContaining({assignment: expect.objectContaining({postManually: false})}),
      )
    })
  })
})
