/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render, wait} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '../../mocks'
import range from 'lodash/range'
import React from 'react'
import {STUDENT_VIEW_QUERY, SUBMISSION_HISTORIES_QUERY} from '../../graphqlData/Queries'
import {SubmissionMocks} from '../../graphqlData/Submission'
import ViewManager from '../ViewManager'

jest.setTimeout(10000)
jest.mock('../Attempt')

async function mockStudentViewResult(overrides = {}) {
  const variables = {assignmentLid: '1', submissionID: '1'}
  const result = await mockQuery(STUDENT_VIEW_QUERY, overrides, variables)
  result.data.assignment.env = {
    assignmentUrl: 'mocked-assignment-url',
    courseId: '1',
    currentUser: {id: '1', display_name: 'bob', avatar_image_url: 'awesome.avatar.url'},
    modulePrereq: null,
    moduleUrl: 'mocked-module-url'
  }
  return result.data
}

async function mockSubmissionHistoriesResult(overrides = {}) {
  const variables = {submissionID: '1', cursor: null}
  const allOverrides = [overrides, {Node: {__typename: 'Submission'}}]
  const result = await mockQuery(SUBMISSION_HISTORIES_QUERY, allOverrides, variables)
  return result.data
}

async function makeProps(opts = {}) {
  const currentAttempt = opts.currentAttempt
  const hasPreviousPage = !!opts.hasPreviousPage
  const numSubmissionHistories =
    opts.numSubmissionHistories === undefined ? currentAttempt - 1 : opts.numSubmissionHistories
  const withDraft = !!opts.withDraft

  // Mock the current submission
  const submittedStateOverrides = currentAttempt === 0 ? {} : SubmissionMocks.submitted
  const studentViewOverrides = [
    {
      Submission: {
        ...submittedStateOverrides,
        attempt: currentAttempt
      }
    }
  ]
  if (withDraft) {
    studentViewOverrides.push({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })
  }
  const studentViewResult = await mockStudentViewResult(studentViewOverrides)

  // Mock the submission histories, as needed.
  let submissionHistoriesResult = null
  if (numSubmissionHistories > 0) {
    const start = currentAttempt - numSubmissionHistories
    const mockedNodeResults = range(start, currentAttempt).map(attempt => ({
      ...SubmissionMocks.graded,
      attempt
    }))

    submissionHistoriesResult = await mockSubmissionHistoriesResult({
      SubmissionHistoryConnection: {nodes: mockedNodeResults},
      PageInfo: {hasPreviousPage}
    })
  }

  return {
    initialQueryData: studentViewResult,
    submissionHistoriesQueryData: submissionHistoriesResult,
    loadMoreSubmissionHistories: jest.fn()
  }
}

describe('ViewManager', () => {
  beforeEach(() => {
    window.ENV = {
      context_asset_string: 'test_1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      PREREQS: {}
    }
  })

  describe('Next Submission Button', () => {
    it('is not displayed if we are at the most current submission', async () => {
      const props = await makeProps({currentAttempt: 1})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Next Submission')).not.toBeInTheDocument()
    })

    it('is not displayed if we are on attempt 0 with a draft', async () => {
      const props = await makeProps({currentAttempt: 0, withDraft: true})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Next Submission')).not.toBeInTheDocument()
    })

    it('is displayed if we are on attempt x with a draft for attempt x+1', async () => {
      const props = await makeProps({currentAttempt: 1, withDraft: true})
      const {getByText, queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(queryByText('View Next Submission')).toBeInTheDocument()
    })

    it('is displayed if we are not at the most current submission', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getByText, queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      await wait(() => expect(queryByText('View Next Submission')).toBeInTheDocument())
    })

    it('changes the currently displayed submission to the next one when clicked', async () => {
      const props = await makeProps({currentAttempt: 3})
      const {getAllByText, getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )

      // The component will always start with the most current submission, so we
      // need to manually go back a few submissions before clicking the next button
      // in order to test this functionality
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      fireEvent.click(prevButton)

      const nextButton = getByText('View Next Submission')
      fireEvent.click(nextButton)

      expect(getAllByText('Attempt 2')[0]).toBeInTheDocument()
    })

    it('sets focus on the next submission button if there is a next submission when clicked', async () => {
      const props = await makeProps({currentAttempt: 3})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      fireEvent.click(prevButton)

      const mockElement = {
        focus: jest.fn()
      }
      document.getElementById = jest.fn().mockReturnValue(mockElement)

      const nextButton = getByText('View Next Submission')
      fireEvent.click(nextButton)

      await wait(() => {
        expect(document.getElementById).toHaveBeenCalledWith('view-next-attempt-button')
        expect(mockElement.focus).toHaveBeenCalled()
      })
    })

    it('sets focus on the new attempt button if there is no next submission and more attempts are allowed when clicked', async () => {
      const props = await makeProps({currentAttempt: 3})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)

      const mockElement = {
        focus: jest.fn()
      }
      document.getElementById = jest.fn().mockReturnValue(mockElement)

      const nextButton = getByText('View Next Submission')
      fireEvent.click(nextButton)

      await wait(() => {
        expect(document.getElementById).toHaveBeenCalledWith('create-new-attempt-button')
        expect(mockElement.focus).toHaveBeenCalled()
      })
    })

    it('sets focus on the previous attempt button if there is no next submission and more attempts are not allowed when clicked', async () => {
      const props = await makeProps({currentAttempt: 3})
      props.initialQueryData.assignment.allowedAttempts = 3
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)

      const mockElement = {
        focus: jest.fn()
      }
      document.getElementById = jest.fn().mockReturnValue(mockElement)

      const nextButton = getByText('View Next Submission')
      fireEvent.click(nextButton)

      await wait(() => {
        expect(document.getElementById).toHaveBeenCalledWith('view-previous-attempt-button')
        expect(mockElement.focus).toHaveBeenCalled()
      })
    })

    it('does not call loadMoreSubmissionHistories() when clicked', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )

      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      const nextButton = getByText('View Next Submission')
      fireEvent.click(nextButton)
      expect(props.loadMoreSubmissionHistories).not.toHaveBeenCalled()
    })
  })

  describe('Previous Submission Button', () => {
    it('is not displayed if we are on attempt 0', async () => {
      const props = await makeProps({currentAttempt: 0})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Previous Submission')).not.toBeInTheDocument()
    })

    it('is not displayed if we are on attempt 0 with a draft', async () => {
      const props = await makeProps({currentAttempt: 0, withDraft: true})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Previous Submission')).not.toBeInTheDocument()
    })

    it('is not displayed if we are on attempt 1', async () => {
      const props = await makeProps({currentAttempt: 1})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Previous Submission')).not.toBeInTheDocument()
    })

    it('is displayed if we are on a resubmit attempt with a draft', async () => {
      const props = await makeProps({currentAttempt: 1, withDraft: true})
      const {queryByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(queryByText('View Previous Submission')).toBeInTheDocument()
    })

    it('is displayed if we are not at the earliest submission', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(getByText('View Previous Submission')).toBeInTheDocument()
    })

    it('is displayed if we are at the earliest loaded submission but have not exhaused pagination', async () => {
      const props = await makeProps({
        currentAttempt: 3,
        hasPreviousPage: true,
        numSubmissionHistories: 1
      })
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(getByText('View Previous Submission')).toBeInTheDocument()
    })

    it('changes the currently displayed submission to the previous one when clicked', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getAllByText, getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(getAllByText('Attempt 1')[0]).toBeInTheDocument()
    })

    it('sets focus on the previous attempt button if there is a previous attempt', async () => {
      const props = await makeProps({currentAttempt: 3})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )

      const mockElement = {
        focus: jest.fn()
      }
      document.getElementById = jest.fn().mockReturnValue(mockElement)

      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)

      await wait(() => {
        expect(document.getElementById).toHaveBeenCalledWith('view-previous-attempt-button')
        expect(mockElement.focus).toHaveBeenCalled()
      })
    })

    it('sets focus on the next attempt button if there is no previous attempt', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )

      const mockElement = {
        focus: jest.fn()
      }
      document.getElementById = jest.fn().mockReturnValue(mockElement)

      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)

      await wait(() => {
        expect(document.getElementById).toHaveBeenCalledWith('view-next-attempt-button')
        expect(mockElement.focus).toHaveBeenCalled()
      })
    })

    it('can navigate backwords from a dummy submission', async () => {
      const props = await makeProps({currentAttempt: 1})
      const {getAllByText, getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const newAttemptButton = getByText('Create New Attempt')
      fireEvent.click(newAttemptButton)
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(getAllByText('Attempt 1')[0]).toBeInTheDocument()
    })

    it('does not call loadMoreSubmissionHistories() when the previous item is already fetched', async () => {
      const props = await makeProps({currentAttempt: 2})
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(props.loadMoreSubmissionHistories).not.toHaveBeenCalled()
    })

    it('calls loadMoreSubmissionHistories() when the previous item has not already been fetched', async () => {
      const props = await makeProps({
        currentAttempt: 3,
        hasPreviousPage: true,
        numSubmissionHistories: 0
      })
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      expect(props.loadMoreSubmissionHistories).toHaveBeenCalledTimes(1)
    })

    it('prevents loadMoreSubmissionHistories() from being called again until graphql query finishes', async () => {
      const props = await makeProps({
        currentAttempt: 3,
        hasPreviousPage: true,
        numSubmissionHistories: 0
      })
      const {getByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )

      const prevButton = getByText('View Previous Submission')
      fireEvent.click(prevButton)
      fireEvent.click(prevButton)
      fireEvent.click(prevButton)
      expect(props.loadMoreSubmissionHistories).toHaveBeenCalledTimes(1)
    })
  })

  describe('New Attempt Button', () => {
    describe('behaves correctly', () => {
      it('by creating a new dummy submission when clicked', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {getAllByText, getByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        const newAttemptButton = getByText('Create New Attempt')
        fireEvent.click(newAttemptButton)
        expect(getAllByText('Attempt 2')[0]).toBeInTheDocument()
      })

      it('by not displaying the new attempt button on a dummy submission', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {queryByText, getByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        const newAttemptButton = getByText('Create New Attempt')
        fireEvent.click(newAttemptButton)
        expect(queryByText('Create New Attempt')).not.toBeInTheDocument()
      })
    })

    describe('when a submission draft exists', () => {
      it('is not displayed when the draft is the selected', async () => {
        const props = await makeProps({currentAttempt: 1, withDraft: true})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('Create New Attempt')).not.toBeInTheDocument()
      })

      it('is not displayed when the most recent submitted attempt is selected', async () => {
        const props = await makeProps({currentAttempt: 1, withDraft: true})
        const {getByText, queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )

        // The draft should be displayed by default on render, so we have to go
        // back one to get to the most recent submitted attempt
        const prevButton = getByText('View Previous Submission')
        fireEvent.click(prevButton)
        expect(queryByText('Create New Attempt')).not.toBeInTheDocument()
      })
    })

    describe('when there is no submission draft', () => {
      it('is not displayed on attempt 0', async () => {
        const props = await makeProps({currentAttempt: 0})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('Create New Attempt')).not.toBeInTheDocument()
      })

      it('is displayed on the latest submitted attempt', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        expect(queryByText('Create New Attempt')).toBeInTheDocument()
      })

      it('sets focus on the previous attempt button when clicked', async () => {
        const props = await makeProps({currentAttempt: 1})
        const {getByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )

        const mockElement = {
          focus: jest.fn()
        }
        document.getElementById = jest.fn().mockReturnValue(mockElement)

        const newButton = getByText('Create New Attempt')
        fireEvent.click(newButton)

        await wait(() => {
          expect(document.getElementById).toHaveBeenCalledWith('view-previous-attempt-button')
          expect(mockElement.focus).toHaveBeenCalled()
        })
      })

      it('is not displayed if you are not on the latest submission attempt', async () => {
        const props = await makeProps({currentAttempt: 3})
        const {getByText, queryByText} = render(
          <MockedProvider>
            <ViewManager {...props} />
          </MockedProvider>
        )
        const prevButton = getByText('View Previous Submission')
        fireEvent.click(prevButton)
        expect(queryByText('Create New Attempt')).not.toBeInTheDocument()
      })
    })
  })

  describe('Submission Drafts', () => {
    it('are initially displayed if they exist', async () => {
      const props = await makeProps({currentAttempt: 1, withDraft: true})
      const {getAllByText} = render(
        <MockedProvider>
          <ViewManager {...props} />
        </MockedProvider>
      )
      expect(getAllByText('Attempt 2')[0]).toBeInTheDocument()
    })
  })
})
