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
import {fireEvent, render} from '@testing-library/react'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {handlers, inboxSettingsHandlers} from '../../../graphql/mswHandlers'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import React from 'react'
import {ConversationContext} from '../../../util/constants'
import * as utils from '../../../util/utils'
import * as uploadFileModule from '@canvas/upload-file'

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
    window.ENV = {
      current_user_id: '1',
      CONVERSATIONS: {
        ATTACHMENTS_FOLDER_ID: 1,
        CAN_MESSAGE_ACCOUNT_CONTEXT: false,
      },
    }
  })

  afterEach(async () => {
    server.resetHandlers()
    // Clear any pending timers
    jest.clearAllTimers()
    // Wait for any pending Apollo operations
    await waitForApolloLoading()
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

  describe('Responsive', () => {
    describe('Mobile', () => {
      beforeEach(() => {
        utils.responsiveQuerySizes.mockReturnValue({
          mobile: {maxWidth: '67'},
        })
      })

      it('Should emit correct testId for mobile compose window', async () => {
        const component = setup()
        await waitForApolloLoading()
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
        await waitForApolloLoading()
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
    await waitForApolloLoading()
    const messageBody = await component.findByTestId('message-body')
    expect(messageBody).toBeInTheDocument()

    // Hit send
    const button = component.getByTestId('send-button')
    fireEvent.click(button)
    // First click should show 'Please select a recipient'
    expect(mockedSetOnFailure).toHaveBeenCalledWith(
      'Please insert a message, Please select a recipient',
      true,
    )

    // Write something invalid
    fireEvent.change(component.getByTestId('compose-modal-header-address-book-input'), {
      target: {value: 'potato'},
    })

    // Hit send again
    fireEvent.click(button)

    // Should still show 'Please select a recipient' since no recipient was selected
    expect(mockedSetOnFailure).toHaveBeenCalledWith(
      'Please insert a message, Please select a recipient',
      true,
    )
  })
})
