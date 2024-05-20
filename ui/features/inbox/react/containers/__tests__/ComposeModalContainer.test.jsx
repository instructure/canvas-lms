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
import {ApolloProvider} from 'react-apollo'
import ComposeModalManager from '../ComposeModalContainer/ComposeModalManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as utils from '../../../util/utils'
import * as uploadFileModule from '@canvas/upload-file'

jest.mock('@canvas/upload-file', () => ({
  uploadFiles: jest.fn().mockResolvedValue([]), // Or any initial mock setup
}))

jest.mock('../../../util/utils', () => ({
  responsiveQuerySizes: jest.fn().mockReturnValue({
    desktop: {minWidth: '768px'},
  }),
}))

describe('ComposeModalContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    server.listen()

    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
    window.ENV = {
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1,
        CAN_MESSAGE_ACCOUNT_CONTEXT: false,
      },
    }
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
            />
          </ConversationContext.Provider>
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files,
      },
    })
  }

  describe('rendering', () => {
    it('should render', () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })
  })

  describe('Include Observers Button', () => {
    beforeEach(() => {
      window.ENV.CONVERSATIONS.CAN_MESSAGE_ACCOUNT_CONTEXT = true
    })

    it('should not render if context is not selected', () => {
      const component = setup()
      expect(component.container).toBeTruthy()
      expect(component.queryByTestId('include-observer-button')).toBeFalsy()
    })

    it('should render if context is selected', async () => {
      const component = setup()

      const select = await component.findByTestId('course-select-modal')
      fireEvent.click(select)
      const selectOptions = await component.findAllByText('Fighting Magneto 101')
      fireEvent.click(selectOptions[0])

      expect(await component.findByTestId('include-observer-button')).toBeTruthy()
    })
  })

  // VICE-4065 - remove or rewrite to remove spies on responsiveQuerySizes import
  describe.skip('Attachments', () => {
    it('attempts to upload a file', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])
      const {findByTestId} = setup()
      const fileInput = await findByTestId('attachment-input')
      const file = new File(['foo'], 'file.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file])

      await waitFor(() =>
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith([file], '/files/pending', {
          conversations: true,
        })
      )
    })

    it('allows uploading multiple files', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'},
      ])
      const {findByTestId} = setup()
      const fileInput = await findByTestId('attachment-input')
      const file1 = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
      const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file1, file2])

      await waitFor(() =>
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith(
          [file1, file2],
          '/files/pending',
          {conversations: true}
        )
      )
    })
  })

  describe('Media', () => {
    it('opens the media upload modal', async () => {
      const container = setup()
      const mediaButton = await container.findByTestId('media-upload')
      fireEvent.click(mediaButton)
      expect(await container.findByText('Upload Media')).toBeInTheDocument()
    })
  })

  describe('Subject', () => {
    it('allows setting the subject', async () => {
      const {findByTestId} = setup()
      const subjectInput = await findByTestId('subject-input')
      fireEvent.click(subjectInput)
      fireEvent.change(subjectInput, {target: {value: 'Potato'}})
      expect(subjectInput.value).toEqual('Potato')
    })
  })

  describe('Body', () => {
    it('allows setting the body', async () => {
      const {findByTestId} = setup()
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

      const selectOptions = await component.findAllByText('Fighting Magneto 101')
      expect(selectOptions.length).toBeGreaterThan(0)
    })

    it('removes enrollment duplicates that come from graphql', async () => {
      const component = setup()

      const select = await component.findByTestId('course-select-modal')
      fireEvent.click(select) // This will fail without the fix because of an unhandled error. We can't have items with duplicate keys because of our jest-setup.

      const selectOptions = await component.findAllByText('Flying The Blackbird')
      expect(selectOptions.length).toBe(1)
    })

    it('does not render All Courses option', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('All Courses')).not.toBeInTheDocument()
      await waitForApolloLoading()
    })

    it('does not render concluded groups', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('concluded_group')).not.toBeInTheDocument()
      await waitForApolloLoading()
    })

    it('does not render concluded courses', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select-modal')
      fireEvent.click(courseDropdown)
      expect(await queryByText('Fighting Magneto 202')).not.toBeInTheDocument()
      await waitForApolloLoading()
    })
  })

  describe('Create Conversation', () => {
    it('does not close modal when an error occurs', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})
      const mockedSetOnFailure = jest.fn().mockResolvedValue({})

      const component = setup({
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess,
        selectedIds: [],
      })

      // Set body
      const bodyInput = await component.findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      expect(mockedSetOnSuccess).not.toHaveBeenCalled()
      expect(mockedSetOnFailure).toHaveBeenCalled()
      expect(await component.findByTestId('compose-modal-desktop')).toBeInTheDocument()
    })
  })

  describe('reply', () => {
    const mockConversation = {
      _id: '1',
      messages: [
        {
          author: {
            _id: '1337',
          },
        },
      ],
    }

    it('does not allow changing the context', async () => {
      const component = setup({isReply: true})
      await waitFor(() => expect(component.queryByText('Loading')).toBeNull())
      expect(component.queryByTestId('course-select-modal')).toBeNull()
    })

    it('does not allow changing the subject', async () => {
      const component = setup({isReply: true})
      await waitFor(() => expect(component.queryByText('Loading')).toBeNull())
      expect(component.queryByTestId('subject-input')).toBeNull()
    })

    it('should include past messages', async () => {
      const component = setup({isReply: true, conversation: mockConversation})
      expect(await component.findByTestId('past-messages')).toBeInTheDocument()
    })

    it('displays specific error message for reply errors', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

      const mockConversationWithError = {
        _id: '3',
        messages: [
          {
            author: {
              _id: '1337',
            },
          },
        ],
      }

      const component = setup({
        setOnSuccess: mockedSetOnSuccess,
        isReply: true,
        conversation: mockConversationWithError,
      })

      // Set body
      const bodyInput = await component.findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)
      await waitFor(() =>
        expect(
          component.queryByText(
            'The following recipients have no active enrollment in the course, ["Student 2"], unable to send messages'
          )
        ).toBeInTheDocument()
      )
    })

    describe('Submission Comments', () => {
      const mockSubmission = {
        _id: '1',
        subject: 'submission1 - course',
        messages: [
          {
            author: {
              _id: '1337',
            },
          },
        ],
      }
      it('should replace compose message with submission subject', async () => {
        const component = setup({
          isReply: true,
          conversation: mockSubmission,
          isSubmissionCommentsType: true,
        })
        await waitFor(() => expect(component.queryByText('Loading')).toBeNull())
        expect(component.queryByText(mockSubmission.subject)).toBeInTheDocument()
        expect(component.queryByText('Compose Message')).not.toBeInTheDocument()
      })

      it('should only have body, cancel, and send inputs', async () => {
        const component = setup({
          isReply: true,
          conversation: mockSubmission,
          isSubmissionCommentsType: true,
        })
        await waitFor(() => expect(component.queryByText('Loading')).toBeNull())

        expect(component.queryByTestId('compose-modal-desktop')).toBeInTheDocument()
        expect(component.queryByTestId('cancel-button')).toBeInTheDocument()
        expect(component.queryByTestId('send-button')).toBeInTheDocument()
        expect(component.queryByTestId('compose-modal-inputs')).not.toBeInTheDocument()
        expect(component.queryByTestId('attachment-upload')).not.toBeInTheDocument()
        expect(component.queryByTestId('attachment-input')).not.toBeInTheDocument()
        expect(component.queryByTestId('media-upload')).not.toBeInTheDocument()
      })

      it('does not display success message when submission reply has errors', async () => {
        const SUBMISSION_ID_THAT_RETURNS_ERROR = '440'
        const mockErrorSubmission = {
          _id: SUBMISSION_ID_THAT_RETURNS_ERROR,
          subject: 'submission1 - course',
          messages: [
            {
              author: {
                _id: '1337',
              },
            },
          ],
        }
        const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

        const component = setup({
          setOnSuccess: mockedSetOnSuccess,
          isReply: true,
          conversation: mockErrorSubmission,
          isSubmissionCommentsType: true,
        })

        // Set body
        const bodyInput = await component.findByTestId('message-body')
        fireEvent.change(bodyInput, {target: {value: 'Potato'}})

        // Hit send
        const button = component.getByTestId('send-button')
        fireEvent.click(button)

        await waitFor(() => expect(mockedSetOnSuccess).not.toHaveBeenCalled())
      })
    })
  })

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        utils.responsiveQuerySizes.mockReturnValue({
          mobile: {maxWidth: '67'},
        })
      })

      it('Should emit correct testId for mobile compose window', async () => {
        const component = setup()
        const modal = await component.findByTestId('compose-modal-mobile')
        expect(modal).toBeTruthy()
      })
    })

    describe('Desktop', () => {
      beforeEach(() => {
        utils.responsiveQuerySizes.mockReturnValue({
          desktop: {minWidth: '768'},
        })
      })

      it('Should emit correct testId for destop compose window', async () => {
        const component = setup()
        const modal = await component.findByTestId('compose-modal-desktop')
        expect(modal).toBeTruthy()
      })
    })
  })

  it('validates recipients', async () => {
    const mockedSetOnFailure = jest.fn().mockResolvedValue({})
    const mockConversation = {
      _id: '1',
      messages: [
        {
          author: {
            _id: '1337',
          },
          recipients: [
            {
              _id: '1337',
            },
            {
              _id: '1338',
            },
          ],
        },
      ],
    }
    const component = setup({
      conversation: mockConversation,
      isForward: true,
      setOnFailure: mockedSetOnFailure,
      selectedIds: [],
    })

    // Wait for modal to load
    await component.findByTestId('message-body')

    // Hit send
    const button = component.getByTestId('send-button')
    fireEvent.click(button)
    expect(mockedSetOnFailure).toHaveBeenCalledWith(
      'Please insert a message body., Please select a recipient.',
      true
    )

    expect(component.findByText('Please select a recipient.')).toBeTruthy()

    // Write something...
    fireEvent.change(component.getByTestId('address-book-input'), {target: {value: 'potato'}})

    // Hit send
    fireEvent.click(button)

    expect(component.findByText('No matches found. Please insert a valid recipient.')).toBeTruthy()
  })

  it('validates course', async () => {
    const component = setup()

    // Wait for modal to load
    await component.findByTestId('message-body')

    // Hit send
    const button = component.getByTestId('send-button')
    fireEvent.click(button)

    expect(component.findByText('Please select a course')).toBeTruthy()
  })
})
