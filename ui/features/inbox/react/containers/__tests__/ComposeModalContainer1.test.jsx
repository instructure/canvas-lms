/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from '@apollo/client'
import ComposeModalManager from '../ComposeModalContainer/ComposeModalManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as utils from '../../../util/utils'
import * as uploadFileModule from '@canvas/upload-file'
import {graphql} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/upload-file')

jest.mock('../../../util/utils', () => ({
  responsiveQuerySizes: jest.fn().mockReturnValue({
    desktop: {minWidth: '768px'},
  }),
}))

describe('ComposeModalContainer', () => {
  const server = mswServer(handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    // Ensure server is clean before starting
    server.close()
    server.listen({onUnhandledRequest: 'error'})

    window.matchMedia = jest.fn().mockImplementation(() => ({
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }))
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
    fakeENV.setup({
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1,
        CAN_MESSAGE_ACCOUNT_CONTEXT: false,
      },
    })
  })

  afterEach(async () => {
    server.resetHandlers()
    // Clear any pending timers
    jest.clearAllTimers()
    // Wait for any pending Apollo operations
    await waitForApolloLoading()
    // Clean up ENV
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({
    setOnFailure = jest.fn(),
    setOnSuccess = jest.fn(),
    isReply,
    isReplyAll,
    isForward,
    conversation,
    selectedIds = ['1'],
    isSubmissionCommentsType = false,
    inboxSignatureBlock = false,
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType}}>
            <ComposeModalManager
              open={true}
              onDismiss={jest.fn()}
              isReply={isReply}
              isReplyAll={isReplyAll}
              isForward={isForward}
              conversation={conversation}
              onSelectedIdsChange={jest.fn()}
              selectedIds={selectedIds}
              inboxSignatureBlock={inboxSignatureBlock}
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>,
    )

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files,
      },
    })
  }

  describe('rendering', () => {
    it('should render', async () => {
      const component = setup()
      await waitForApolloLoading()
      expect(component.container).toBeTruthy()
    })
  })

  describe('Include Observers Button', () => {
    beforeEach(() => {
      fakeENV.setup({
        current_user_id: '1',
        CONVERSATIONS: {
          ATTACHMENTS_FOLDER_ID: 1,
          CAN_MESSAGE_ACCOUNT_CONTEXT: true,
        },
      })
      // Mock the courses data to ensure we have a teacher enrollment
      server.use(
        graphql.query('GetConversationCourses', (_req, res, ctx) => {
          return res(
            ctx.data({
              legacyNode: {
                id: '1',
                __typename: 'User',
                enrollments: [
                  {
                    id: '1',
                    type: 'TeacherEnrollment',
                    course: {
                      name: 'Fighting Magneto 101',
                      assetString: 'course_1',
                      id: '1',
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                favoriteCoursesConnection: {
                  nodes: [
                    {
                      name: 'Fighting Magneto 101',
                      assetString: 'course_1',
                      id: '1',
                      __typename: 'Course',
                    },
                  ],
                  __typename: 'CourseConnection',
                },
                // User __typename is already defined in the parent object
              },
            }),
          )
        }),
      )
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('should not render if context is not selected', async () => {
      const component = setup()
      await waitForApolloLoading()
      expect(component.container).toBeTruthy()
      expect(component.queryByTestId('include-observer-button')).toBeFalsy()
    })

    it('should render if context is selected', async () => {
      // Create a spy for the getRecipientsObserver function
      const getRecipientsObserverMock = jest.fn()

      // Setup the component with the necessary props
      const component = render(
        <ApolloProvider client={mswClient}>
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
              <ComposeModalManager
                open={true}
                onDismiss={jest.fn()}
                selectedIds={['1']}
                onSelectedIdsChange={jest.fn()}
                // This is the key part - we need to set the activeCourseFilterID
                activeCourseFilterID="course_1"
                // Mock the getRecipientsObserver function
                getRecipientsObserver={getRecipientsObserverMock}
              />
            </ConversationContext.Provider>
          </AlertManagerContext.Provider>
        </ApolloProvider>,
      )

      // Wait for Apollo queries to complete
      await waitForApolloLoading()

      // Wait for the component to update and check if the button is visible
      await waitFor(
        () => {
          const button = component.queryByTestId('include-observer-button')
          expect(button).toBeInTheDocument()
        },
        {timeout: 3000},
      )
    })
  })

  it('validates course', async () => {
    const component = setup()

    // Wait for modal and Apollo queries to complete
    await waitForApolloLoading()
    const messageBody = await component.findByTestId('message-body')
    expect(messageBody).toBeInTheDocument()

    // Hit send
    const button = component.getByTestId('send-button')
    fireEvent.click(button)

    // More specific error expectation
    const errorMessage = await component.findByText('Please select a course')
    expect(errorMessage).toBeInTheDocument()
  })

  describe('Attachments', () => {
    beforeEach(() => {
      // Reset upload mock before each test
      uploadFileModule.uploadFiles.mockReset()
    })

    it('attempts to upload a file', async () => {
      const mockUploadResult = [{id: '1', name: 'file1.jpg'}]
      uploadFileModule.uploadFiles.mockResolvedValue(mockUploadResult)

      const {findByTestId} = setup()
      await waitForApolloLoading()

      const fileInput = await findByTestId('attachment-input')
      expect(fileInput).toBeInTheDocument()

      const file = new File(['foo'], 'file.pdf', {type: 'application/pdf'})
      uploadFiles(fileInput, [file])

      await waitFor(() => {
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith([file], '/files/pending', {
          conversations: true,
        })
      })
    })

    it('allows uploading multiple files', async () => {
      const mockUploadResult = [
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'},
      ]
      uploadFileModule.uploadFiles.mockResolvedValue(mockUploadResult)

      const {findByTestId} = setup()
      await waitForApolloLoading()

      const fileInput = await findByTestId('attachment-input')
      expect(fileInput).toBeInTheDocument()

      const file1 = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
      const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file1, file2])

      await waitFor(() => {
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith(
          [file1, file2],
          '/files/pending',
          {conversations: true},
        )
      })
    })
  })

  describe('Media', () => {
    it('opens the media upload modal', async () => {
      const container = setup()
      await waitForApolloLoading()
      const mediaButton = await container.findByTestId('media-upload')
      fireEvent.click(mediaButton)
      expect(await container.findByText('Upload Media')).toBeInTheDocument()
    })
  })

  describe('Subject', () => {
    it('allows setting the subject', async () => {
      const {findByTestId} = setup()
      await waitForApolloLoading()
      const subjectInput = await findByTestId('subject-input')
      fireEvent.click(subjectInput)
      fireEvent.change(subjectInput, {target: {value: 'Potato'}})
      expect(subjectInput.value).toEqual('Potato')
    })
  })

  describe('Body', () => {
    it('allows setting the body', async () => {
      const {findByTestId} = setup()
      await waitForApolloLoading()
      const bodyInput = await findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})
      expect(bodyInput.value).toEqual('Potato')
    })
  })

  describe('Course Select', () => {
    it('queries graphql for courses', async () => {
      const component = setup()

      const select = await component.findByTestId('course-select-modal')
      fireEvent.click(select)

      const selectOptions = await component.findAllByText('Ipsum')
      expect(selectOptions.length).toBeGreaterThan(0)
    })

    it('removes enrollment duplicates that come from graphql', async () => {
      const component = setup()

      const select = await component.findByTestId('course-select-modal')
      fireEvent.click(select) // This will fail without the fix because of an unhandled error. We can't have items with duplicate keys because of our jest-setup.

      const selectOptions = await component.findAllByText('Ipsum')
      expect(selectOptions).toHaveLength(3) // Should only have 3 unique courses
    })

    it('does not render All Courses option', async () => {
      const {findByTestId, queryByText} = setup()
      await waitForApolloLoading()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('All Courses')).not.toBeInTheDocument()
    })

    it('does not render concluded groups', async () => {
      const {findByTestId, queryByText} = setup()
      await waitForApolloLoading()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('concluded_group')).not.toBeInTheDocument()
    })

    it('does not render concluded courses', async () => {
      const {findByTestId, queryByText} = setup()
      await waitForApolloLoading()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('Fighting Magneto 202')).not.toBeInTheDocument()
    })
  })
})
