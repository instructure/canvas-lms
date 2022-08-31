/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {fireEvent, render, waitFor, within} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import {initializeReaderButton} from '../../../../../shared/immersive-reader/ImmersiveReader'
import React from 'react'
import StudentContent from '../StudentContent'
import {AssignmentMocks} from '@canvas/assignments/graphql/student/Assignment'
import ContextModuleApi from '../../apis/ContextModuleApi'
import {RUBRIC_QUERY, SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'

jest.mock('../AttemptSelect')

jest.mock('../../apis/ContextModuleApi')

jest.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn()
  }
})

describe('Assignment Student Content View', () => {
  beforeEach(() => {
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  it('renders the student header if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByTestId('assignments-2-student-view')).toBeInTheDocument()
  })

  it('renders the student header if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true}
    })
    const {getByTestId} = render(<StudentContent {...props} />)
    expect(getByTestId('assignment-student-header')).toBeInTheDocument()
  })

  it('renders the assignment details and student content if the assignment is unlocked', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText, queryByText} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>
    )
    expect(getByText('Details')).toBeInTheDocument()
    expect(queryByText('Availability Dates')).not.toBeInTheDocument()
  })

  describe('when the assignment does not expect digital submissions', () => {
    let props
    let oldEnv

    beforeEach(async () => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}

      props = await mockAssignmentAndSubmission({
        Assignment: {
          ...AssignmentMocks.onPaper,
          name: 'this is my assignment'
        },
        Submission: {}
      })
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders the assignment details', async () => {
      const {getAllByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getAllByText(/this is my assignment/)).not.toHaveLength(0)
    })

    it('does not render the interface for submitting to the assignment', async () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('assignment-2-student-content-tabs')).not.toBeInTheDocument()
    })

    it('renders a "Mark as Done" button if the assignment is part of a module with a mark-as-done requirement', async () => {
      window.ENV.CONTEXT_MODULE_ITEM = {
        done: false,
        id: '123',
        module_id: '456'
      }

      const {getByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByRole('button', {name: 'Mark as done'})).toBeInTheDocument()
    })

    it('does not render a "Mark as Done" button if the assignment lacks mark-as-done requirements', async () => {
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', {name: 'Mark as done'})).not.toBeInTheDocument()
    })

    it('renders the rubric if the assignment has one', async () => {
      window.ENV.ASSIGNMENT_ID = '1'
      window.ENV.COURSE_ID = '1'
      props.assignment.rubric = {}

      const variables = {
        assignmentLid: '1',
        courseID: '1',
        submissionAttempt: 0,
        submissionID: '1'
      }
      const overrides = {
        Account: {outcomeProficiency: {proficiencyRatingsConnection: null}},
        Assignment: {rubric: {}},
        Course: {id: '1'},
        Node: {__typename: 'Assignment'},
        Rubric: {
          criteria: [],
          title: 'Some On-paper Rubric'
        }
      }
      const result = await mockQuery(RUBRIC_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: RUBRIC_QUERY,
            variables
          },
          result
        }
      ]

      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(await findByText('View Rubric')).toBeInTheDocument()
    })

    describe('module links', () => {
      beforeEach(() => {
        window.ENV.ASSIGNMENT_ID = '1'
        window.ENV.COURSE_ID = '1'

        ContextModuleApi.getContextModuleData.mockClear()
      })

      it('renders next and previous module links if they exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({
          next: {url: '/next', tooltipText: {string: 'Next'}},
          previous: {url: '/previous', tooltipText: {string: 'Previous'}}
        })

        const {getByTestId} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        const footer = getByTestId('student-footer')
        expect(within(footer).getByRole('link', {name: /Previous/})).toBeInTheDocument()
        expect(within(footer).getByRole('link', {name: /Next/})).toBeInTheDocument()
      })

      it('does not render module links if no next/previous modules exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({})

        const {queryByRole} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })
  })

  describe('when the comments tray is opened', () => {
    const makeMocks = async () => {
      const variables = {submissionAttempt: 0, submissionId: '1'}
      const overrides = {
        Node: {__typename: 'Submission'},
        SubmissionCommentConnection: {nodes: []}
      }
      const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: SUBMISSION_COMMENT_QUERY,
            variables
          },
          result
        }
      ]
      return mocks
    }

    // https://instructure.atlassian.net/browse/USERS-385
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('renders Comments', async () => {
      // To be unskipped in EVAL-1679
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('Add Comment'))
      await waitFor(() => expect(getByText('Send Comment')).toBeInTheDocument())
    })

    it('renders spinner while lazy loading comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getAllByTitle, getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>
      )
      fireEvent.click(getByText('Add Comment'))
      expect(getAllByTitle('Loading')[0]).toBeInTheDocument()
    })
  })

  describe('concluded enrollment notice', () => {
    const concludedMatch = /your enrollment in this course has been concluded/

    let oldEnv

    beforeEach(() => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders when the current enrollment is concluded', async () => {
      window.ENV.enrollment_state = 'completed'

      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(getByText(concludedMatch)).toBeInTheDocument()
    })

    it('does not render when the current enrollment is not concluded', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      expect(queryByText(concludedMatch)).not.toBeInTheDocument()
    })
  })

  describe('number of attempts', () => {
    it('renders the number of attempts with one attempt', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1}
      })

      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('1 Attempt Allowed')).toBeInTheDocument()
    })

    it('renders the number of attempts with unlimited attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: null}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('Unlimited Attempts Allowed')).toBeInTheDocument()
    })

    it('renders the number of attempts with multiple attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('3 Attempts Allowed')).toBeInTheDocument()
    })

    it('does not render the number of attempts if the assignment does not involve digital submissions', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {...AssignmentMocks.onPaper}
      })

      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByText('3 Attempts Allowed')).not.toBeInTheDocument()
    })

    it('does not render the number of attempts if peer review mode is enabled', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3}
      })
      props.assignment.env.peerReviewModeEnabled = true
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(queryByText('3 Attempts Allowed')).not.toBeInTheDocument()
    })

    it('takes into account extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {extraAttempts: 2}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('5 Attempts Allowed')).toBeInTheDocument()
    })

    it('treats a null value for extraAttempts as zero', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 3},
        Submission: {extraAttempts: null}
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(getByText('3 Attempts Allowed')).toBeInTheDocument()
    })
  })

  describe('availability dates', () => {
    it('renders AvailabilityDates', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          unlockAt: '2016-07-11T18:00:00-01:00',
          lockAt: '2016-11-11T18:00:00-01:00'
        }
      })
      const {getAllByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      // Reason why this is showing up twice is once for screenreader content and again for regular content
      expect(getAllByText('Available: Jul 11, 2016 7:00pm')).toHaveLength(2)
    })
  })

  describe('Unpublished module', () => {
    it('renders UnpublishedModule', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.belongsToUnpublishedModule = true
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        getByText('This assignment is part of an unpublished module and is not available yet.')
      ).toBeInTheDocument()
    })
  })

  describe('Unavailable peer review', () => {
    it('is rendered when peerReviewModeEnabled is true and peerReviewAvailable is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = false
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        getByText('There are no submissions available to review just yet.')
      ).toBeInTheDocument()
      expect(getByText('Please check back soon.')).toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is true and peerReviewAvailable is true', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = true
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })

    it('is not rendered when peerReviewModeEnabled is false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      const {queryByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )
      expect(
        queryByText('There are no submissions available to review just yet.')
      ).not.toBeInTheDocument()
      expect(queryByText('Please check back soon.')).not.toBeInTheDocument()
    })
  })

  describe('Immersive Reader', () => {
    let element
    let props

    beforeEach(async () => {
      props = await mockAssignmentAndSubmission({
        Assignment: {
          description: 'description',
          name: 'name'
        }
      })
    })

    afterEach(() => {
      element?.remove()
      initializeReaderButton.mockClear()
    })

    it('sets up Immersive Reader if it finds the mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name'
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('sets up Immersive Reader if it finds the mobile mount point', async () => {
      element = document.createElement('div')
      element.id = 'immersive_reader_mobile_mount_point'
      document.documentElement.append(element)

      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await waitFor(() => {
        expect(initializeReaderButton).toHaveBeenCalledWith(element, {
          content: expect.anything(Function),
          title: 'name'
        })

        expect(initializeReaderButton.mock.calls[0][1].content()).toEqual('description')
      })
    })

    it('does not set up Immersive Reader if neither mount point is present', async () => {
      render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>
      )

      await new Promise(resolve => setTimeout(resolve, 0))
      expect(initializeReaderButton).not.toHaveBeenCalled()
    })
  })
})
