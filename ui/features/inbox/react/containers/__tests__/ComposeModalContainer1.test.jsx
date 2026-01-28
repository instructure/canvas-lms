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
import {cleanup, fireEvent, render, waitFor} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {setupServer} from 'msw/node'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as uploadFileModule from '@canvas/upload-file'
import fakeENV from '@canvas/test-utils/fakeENV'

if (typeof vi !== 'undefined') vi.mock('@canvas/upload-file')
vi.mock('@canvas/upload-file')

vi.mock('../../../util/utils', async () => ({
  ...(await vi.importActual('../../../util/utils')),
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
    cleanup()
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
})
