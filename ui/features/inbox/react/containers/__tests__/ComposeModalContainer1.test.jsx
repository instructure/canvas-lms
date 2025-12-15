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
import {setupServer} from 'msw/node'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as utils from '../../../util/utils'
import * as uploadFileModule from '@canvas/upload-file'
import {graphql, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'

 
if (typeof vi !== 'undefined') vi.mock('@canvas/upload-file')
vi.mock('@canvas/upload-file')

vi.mock('../../../util/utils', async () => ({
  ...await vi.importActual('../../../util/utils'),
  responsiveQuerySizes: vi.fn().mockReturnValue({
    desktop: {minWidth: '768px'},
  }),
}))

describe('ComposeModalContainer', () => {
  const server = setupServer(...handlers.concat(inboxSettingsHandlers()))

  beforeAll(() => {
    // Ensure server is clean before starting
    server.close()
    server.listen({onUnhandledRequest: 'error'})

    window.matchMedia = vi.fn().mockImplementation(() => ({
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }))
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles.mockResolvedValue([])
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
    vi.clearAllTimers()
    // Wait for any pending Apollo operations
    await waitForApolloLoading()
    // Clean up ENV
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  const setup = ({
    setOnFailure = vi.fn(),
    setOnSuccess = vi.fn(),
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
              onDismiss={vi.fn()}
              isReply={isReply}
              isReplyAll={isReplyAll}
              isForward={isForward}
              conversation={conversation}
              onSelectedIdsChange={vi.fn()}
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
      vi.clearAllMocks()
    })

    it('should not render if context is not selected', async () => {
      const component = setup()
      await waitForApolloLoading()
      expect(component.container).toBeTruthy()
      expect(component.queryByTestId('include-observer-button')).toBeFalsy()
    })

    it('should render if context is selected', async () => {
      // Create a spy for the getRecipientsObserver function
      const getRecipientsObserverMock = vi.fn()

      // Setup the component with the necessary props
      const component = render(
        <ApolloProvider client={mswClient}>
          <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
            <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
              <ComposeModalManager
                open={true}
                onDismiss={vi.fn()}
                selectedIds={['1']}
                onSelectedIdsChange={vi.fn()}
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

    it('should fetch all observers when button is clicked (single page)', async () => {
      const onSelectedIdsChange = vi.fn()

      // Setup MSW handler for single page response
      server.use(
        graphql.query('GetRecipientsObservers', ({variables}) => {
          return HttpResponse.json({
            data: {
              legacyNode: {
                id: 'VXNlci0x',
                __typename: 'User',
                recipientsObservers: {
                  nodes: [
                    {
                      id: 'observer_3',
                      name: 'Observer 1',
                      __typename: 'MessageableUser',
                      _id: '3',
                    },
                    {
                      id: 'observer_4',
                      name: 'Observer 2',
                      __typename: 'MessageableUser',
                      _id: '4',
                    },
                  ],
                  pageInfo: {
                    hasNextPage: false,
                    endCursor: null,
                    __typename: 'PageInfo',
                  },
                },
              },
            },
          })
        }),
      )

      const component = render(
        <ApolloProvider client={mswClient}>
          <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
            <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
              <ComposeModalManager
                open={true}
                onDismiss={vi.fn()}
                selectedIds={[
                  {id: 'user_1', _id: '1', name: 'Student 1'},
                  {id: 'user_2', _id: '2', name: 'Student 2'},
                ]}
                onSelectedIdsChange={onSelectedIdsChange}
                activeCourseFilterID="course_1"
              />
            </ConversationContext.Provider>
          </AlertManagerContext.Provider>
        </ApolloProvider>,
      )

      await waitForApolloLoading()

      // Find and click the include observers button
      const button = await component.findByTestId('include-observer-button')
      expect(button).toBeInTheDocument()
      fireEvent.click(button)

      // Wait for observers to be fetched and onSelectedIdsChange to be called
      await waitFor(
        () => {
          expect(onSelectedIdsChange).toHaveBeenCalled()
          const callArgs =
            onSelectedIdsChange.mock.calls[onSelectedIdsChange.mock.calls.length - 1][0]
          // Should have original 2 recipients plus 2 observers = 4 total
          expect(callArgs).toHaveLength(4)
          // Check that observers were added
          const observerIds = callArgs.map(r => r._id)
          expect(observerIds).toContain('3')
          expect(observerIds).toContain('4')
        },
        {timeout: 3000},
      )
    })

    it('should fetch all observers across multiple pages when button is clicked', async () => {
      let callCount = 0
      const onSelectedIdsChange = vi.fn()

      // Setup MSW handler for multi-page response
      server.use(
        graphql.query('GetRecipientsObservers', ({variables}) => {
          callCount++

          // First page
          if (!variables.after || variables.after === null) {
            return HttpResponse.json({
              data: {
                legacyNode: {
                  id: 'VXNlci0x',
                  __typename: 'User',
                  recipientsObservers: {
                    nodes: Array.from({length: 20}, (_, i) => ({
                      id: `observer_${i + 1}`,
                      name: `Observer ${i + 1}`,
                      __typename: 'MessageableUser',
                      _id: `${i + 1}`,
                    })),
                    pageInfo: {
                      hasNextPage: true,
                      endCursor: 'cursor1',
                      __typename: 'PageInfo',
                    },
                  },
                },
              },
            })
          }

          // Second page
          if (variables.after === 'cursor1') {
            return HttpResponse.json({
              data: {
                legacyNode: {
                  id: 'VXNlci0x',
                  __typename: 'User',
                  recipientsObservers: {
                    nodes: Array.from({length: 10}, (_, i) => ({
                      id: `observer_${i + 21}`,
                      name: `Observer ${i + 21}`,
                      __typename: 'MessageableUser',
                      _id: `${i + 21}`,
                    })),
                    pageInfo: {
                      hasNextPage: false,
                      endCursor: null,
                      __typename: 'PageInfo',
                    },
                  },
                },
              },
            })
          }
        }),
      )

      const component = render(
        <ApolloProvider client={mswClient}>
          <AlertManagerContext.Provider value={{setOnFailure: vi.fn(), setOnSuccess: vi.fn()}}>
            <ConversationContext.Provider value={{isSubmissionCommentsType: false}}>
              <ComposeModalManager
                open={true}
                onDismiss={vi.fn()}
                selectedIds={[
                  {id: 'user_100', _id: '100', name: 'Student 1'},
                  {id: 'user_101', _id: '101', name: 'Student 2'},
                ]}
                onSelectedIdsChange={onSelectedIdsChange}
                activeCourseFilterID="course_1"
              />
            </ConversationContext.Provider>
          </AlertManagerContext.Provider>
        </ApolloProvider>,
      )

      await waitForApolloLoading()

      // Find and click the include observers button
      const button = await component.findByTestId('include-observer-button')
      expect(button).toBeInTheDocument()
      fireEvent.click(button)

      // Wait for all observers to be fetched across pages
      await waitFor(
        () => {
          expect(onSelectedIdsChange).toHaveBeenCalled()
          // Verify multiple pages were fetched
          expect(callCount).toBeGreaterThanOrEqual(2)

          const callArgs =
            onSelectedIdsChange.mock.calls[onSelectedIdsChange.mock.calls.length - 1][0]
          // Should have original 2 recipients plus 30 observers = 32 total
          expect(callArgs).toHaveLength(32)

          // Check that observers from both pages were added
          const observerIds = callArgs.map(r => r._id)
          expect(observerIds).toContain('1') // from first page
          expect(observerIds).toContain('30') // from second page
        },
        {timeout: 5000},
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
      fireEvent.click(select) // This will fail without the fix because of an unhandled error. We can't have items with duplicate keys because of our vi-setup.

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
