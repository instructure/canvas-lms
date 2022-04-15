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

import * as uploadFileModule from '@canvas/upload-file'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import ComposeModalManager from '../ComposeModalContainer/ComposeModalManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {responsiveQuerySizes} from '../../../util/utils'
import {ConversationContext} from '../../../util/constants'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('ComposeModalContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    // Add appropriate mocks for responsive
    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    // Repsonsive Query Mock Default
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {minWidth: '768px'}
    }))
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  beforeEach(() => {
    uploadFileModule.uploadFiles = jest.fn().mockResolvedValue([])
    window.ENV = {
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1
      }
    }
  })

  const setup = ({
    setOnFailure = jest.fn(),
    setOnSuccess = jest.fn(),
    isReply,
    isReplyAll,
    isForward,
    conversation,
    selectedIds = [],
    isSubmissionCommentsType = false
  } = {}) =>
    render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <ConversationContext.Provider value={{isSubmissionCommentsType}}>
            <ComposeModalManager
              open
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
        files
      }
    })
  }

  describe('rendering', () => {
    it('should render', () => {
      const component = setup()
      expect(component.container).toBeTruthy()
    })
  })

  describe('Attachments', () => {
    it('attempts to upload a file', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([{id: '1', name: 'file1.jpg'}])
      const {findByTestId} = setup()
      const fileInput = await findByTestId('attachment-input')
      const file = new File(['foo'], 'file.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file])

      await waitFor(() =>
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith([file], '/api/v1/folders/1/files')
      )
    })

    it('allows uploading multiple files', async () => {
      uploadFileModule.uploadFiles.mockResolvedValue([
        {id: '1', name: 'file1.jpg'},
        {id: '2', name: 'file2.jpg'}
      ])
      const {findByTestId} = setup()
      const fileInput = await findByTestId('attachment-input')
      const file1 = new File(['foo'], 'file1.pdf', {type: 'application/pdf'})
      const file2 = new File(['foo'], 'file2.pdf', {type: 'application/pdf'})

      uploadFiles(fileInput, [file1, file2])

      await waitFor(() =>
        expect(uploadFileModule.uploadFiles).toHaveBeenCalledWith(
          [file1, file2],
          '/api/v1/folders/1/files'
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

  describe('Send individual messages', () => {
    it('allows toggling the setting', async () => {
      const {findByTestId} = setup()
      const checkbox = await findByTestId('individual-message-checkbox')
      expect(checkbox.checked).toBe(false)

      fireEvent.click(checkbox)
      expect(checkbox.checked).toBe(true)

      fireEvent.click(checkbox)
      expect(checkbox.checked).toBe(false)
    })
  })

  describe('Course Select', () => {
    it('queries graphql for courses', async () => {
      const component = setup()

      const select = await component.findByTestId('course-select')
      fireEvent.click(select)

      const selectOptions = await component.findAllByText('Fighting Magneto 101')
      expect(selectOptions.length).toBeGreaterThan(0)
    })

    it('does not render All Courses option', async () => {
      const {findByTestId, queryByText} = setup()
      const courseDropdown = await findByTestId('course-select')
      fireEvent.click(courseDropdown)
      expect(await queryByText('All Courses')).not.toBeInTheDocument()
      await waitForApolloLoading()
    })
  })

  describe('Create Conversation', () => {
    it('allows creating conversations', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

      const component = setup({setOnSuccess: mockedSetOnSuccess})

      // Set subject
      const subjectInput = await component.findByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'Potato Subject'}})

      // Set body
      const bodyInput = component.getByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
    })
  })

  describe('reply', () => {
    const mockConversation = {
      _id: '1',
      messages: [
        {
          author: {
            _id: '1337'
          }
        }
      ]
    }

    it('does not allow changing the context', async () => {
      const component = setup({isReply: true})
      await waitFor(() => expect(component.queryByText('Loading')).toBeNull())
      expect(component.queryByTestId('course-select')).toBeNull()
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

    it('allows replying to a conversation', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

      const component = setup({
        setOnSuccess: mockedSetOnSuccess,
        isReply: true,
        conversation: mockConversation
      })

      // Set body
      const bodyInput = await component.findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
    })

    describe('Submission Comments', () => {
      const mockSubmission = {
        _id: '1',
        subject: 'submission1 - course',
        messages: [
          {
            author: {
              _id: '1337'
            }
          }
        ]
      }
      it('should replace compose message with submission subject', async () => {
        const component = setup({
          isReply: true,
          conversation: mockSubmission,
          isSubmissionCommentsType: true
        })
        await waitFor(() => expect(component.queryByText('Loading')).toBeNull())
        expect(component.queryByText(mockSubmission.subject)).toBeInTheDocument()
        expect(component.queryByText('Compose Message')).not.toBeInTheDocument()
      })

      it('should only have body, cancel, and send inputs', async () => {
        const component = setup({
          isReply: true,
          conversation: mockSubmission,
          isSubmissionCommentsType: true
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

      it('allows replying to a submission', async () => {
        const mockedSetOnSuccess = jest.fn().mockResolvedValue({})

        const component = setup({
          setOnSuccess: mockedSetOnSuccess,
          isReply: true,
          conversation: mockSubmission,
          isSubmissionCommentsType: true
        })

        // Set body
        const bodyInput = await component.findByTestId('message-body')
        fireEvent.change(bodyInput, {target: {value: 'Potato'}})

        // Hit send
        const button = component.getByTestId('send-button')
        fireEvent.click(button)

        await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
      })
    })
  })

  describe('replyAll', () => {
    it('allows replying all to a conversation', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})
      const mockConversation = {
        _id: '1',
        messages: [
          {
            author: {
              _id: '1337'
            },
            recipients: [
              {
                _id: '1337'
              },
              {
                _id: '1338'
              }
            ]
          }
        ]
      }

      const component = setup({
        setOnSuccess: mockedSetOnSuccess,
        isReplyAll: true,
        conversation: mockConversation
      })

      // Set body
      const bodyInput = await component.findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
    })
  })

  describe('forward', () => {
    it('allows replying all to a conversation', async () => {
      const mockedSetOnSuccess = jest.fn().mockResolvedValue({})
      const mockConversation = {
        _id: '1',
        messages: [
          {
            author: {
              _id: '1337'
            },
            recipients: [
              {
                _id: '1337'
              },
              {
                _id: '1338'
              }
            ]
          }
        ]
      }

      const component = setup({
        setOnSuccess: mockedSetOnSuccess,
        isReplyAll: true,
        conversation: mockConversation
      })

      // Set body
      const bodyInput = await component.findByTestId('message-body')
      fireEvent.change(bodyInput, {target: {value: 'Potato'}})

      // Hit send
      const button = component.getByTestId('send-button')
      fireEvent.click(button)

      await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalled())
    })
  })

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          mobile: {maxWidth: '67'}
        }))
      })

      it('Should emit correct testId for mobile compose window', async () => {
        const component = setup()
        const modal = await component.findByTestId('compose-modal-mobile')
        expect(modal).toBeTruthy()
      })
    })

    describe('Desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {minWidth: '768'}
        }))
      })

      it('Should emit correct testId for destop compose window', async () => {
        const component = setup()
        const modal = await component.findByTestId('compose-modal-desktop')
        expect(modal).toBeTruthy()
      })
    })
  })
})
