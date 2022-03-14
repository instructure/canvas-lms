/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import CanvasInbox from '../CanvasInbox'
import {ApolloProvider} from 'react-apollo'
import React from 'react'
import {render, fireEvent, waitFor} from '@testing-library/react'
import {responsiveQuerySizes} from '../../../util/utils'
import {mswClient} from '../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../shared/msw/mswServer'
import {handlers} from '../../../graphql/mswHandlers'
import waitForApolloLoading from '../../../util/waitForApolloLoading'
import {graphql} from 'msw'
import {ConversationParticipant} from '../../../graphql/ConversationParticipant'
import {Conversation} from '../../../graphql/Conversation'

jest.mock('../../../util/utils', () => ({
  ...jest.requireActual('../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('CanvasInbox Full Page', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
    window.ENV = {
      current_user: {
        id: '9'
      }
    }

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

  beforeEach(() => {
    mswClient.cache.reset()
    window.location.hash = ''
  })

  afterEach(() => {
    server.resetHandlers()
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = () => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <CanvasInbox />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }

  describe('Desktop', () => {
    beforeAll(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {minWidth: '768px'}
      }))
    })

    test('toggles between inbox and sent scopes', async () => {
      const container = setup()
      await waitForApolloLoading()
      const conversationNode = await container.findByTestId('conversation')
      expect(conversationNode).toHaveTextContent('this is a message for the inbox')

      const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
      fireEvent.click(mailboxDropdown)
      await waitForApolloLoading()

      const option = await container.findByText('Sent')

      expect(option).toBeTruthy()

      fireEvent.click(option)

      await waitForApolloLoading()

      const sentConversationNodes = await container.findAllByTestId('conversation')
      expect(sentConversationNodes[0]).toHaveTextContent('this is the first reply message')
      expect(sentConversationNodes[1]).toHaveTextContent('this is the second reply message')
    })

    it('renders the conversation messages', async () => {
      const container = setup()
      await waitForApolloLoading()

      const conversation = await container.findByTestId('conversationListItem-Checkbox')
      fireEvent.click(conversation)
      await waitForApolloLoading()

      expect(await container.findByText('this is the first reply message')).toBeInTheDocument()
      expect(await container.findByText('this is a reply all')).toBeInTheDocument()
      expect(await container.findByText('testing 123')).toBeInTheDocument()
    })

    // TODO: will be fixed with VICE-2077
    it.skip('should change the read state of a conversation', async () => {
      const container = setup()
      const conversation = await container.findByTestId('conversationListItem-Checkbox')
      fireEvent.click(conversation)
      await container.findByText('Watch out for that Magneto guy')
      expect(container.queryByTestId('unread-badge')).toBeTruthy()
      const settings = await container.findByTestId('settings')
      fireEvent.click(settings)
      const markAsReadButton = await container.findByText('Mark as read')
      fireEvent.click(markAsReadButton)
      expect(container.queryByTestId('unread-badge')).toBeFalsy()
    })

    it('Successfully star selected conversation', async () => {
      const {findAllByTestId, findByTestId, getByText} = setup()

      const checkboxes = await findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.length).toBe(1)
      fireEvent.click(checkboxes[0])

      const settingsCog = await findByTestId('settings')
      fireEvent.click(settingsCog)

      const star = getByText('Star')
      fireEvent.click(star)

      await waitFor(() =>
        expect(setOnSuccess).toHaveBeenCalledWith('The conversation has been successfully starred.')
      )
    })

    it('Successfully star selected conversations', async () => {
      server.use(
        graphql.query('GetConversationsQuery', (req, res, ctx) => {
          const data = {
            legacyNode: {
              _id: '9',
              id: 'VXNlci05',
              conversationsConnection: {
                nodes: [
                  {
                    ...ConversationParticipant.mock(),
                    conversation: Conversation.mock()
                  },
                  {
                    ...ConversationParticipant.mock({
                      _id: '257',
                      id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4',
                      workflowState: 'unread'
                    }),
                    conversation: Conversation.mock()
                  }
                ],
                __typename: 'ConversationParticipantConnection'
              },
              __typename: 'User'
            }
          }

          return res.once(ctx.data(data))
        })
      )

      const container = setup()

      const checkboxes = await container.findAllByTestId('conversationListItem-Checkbox')
      expect(checkboxes.length).toBe(2)
      fireEvent.click(checkboxes[0])
      fireEvent.click(checkboxes[1])

      const settingsCog = await container.findByTestId('settings')
      fireEvent.click(settingsCog)

      const star = container.getByText('Star')
      fireEvent.click(star)

      await waitFor(() =>
        expect(setOnSuccess).toHaveBeenCalledWith(
          'The conversations has been successfully starred.'
        )
      )
    })

    it('should check then uncheck a checkbox', async () => {
      const container = setup()

      const checkbox = await container.findByTestId('conversationListItem-Checkbox')
      expect(checkbox.checked).toBeFalsy()
      fireEvent.click(checkbox)
      expect(checkbox.checked).toBeTruthy()
      fireEvent.click(checkbox)
      expect(checkbox.checked).toBeFalsy()
    })

    it('should trigger confirm when deleting from MessageListActions', async () => {
      window.confirm = jest.fn(() => true)
      const container = setup()

      const conversation = await container.findByTestId('conversationListItem-Checkbox')
      fireEvent.click(conversation)

      const deleteBtn = await container.findByTestId('delete')
      fireEvent.click(deleteBtn)
      expect(window.confirm).toHaveBeenCalled()
    })

    it('should trigger confirm when deleting from message kebab menu', async () => {
      window.confirm = jest.fn(() => true)
      const container = setup()

      const conversation = await container.findByTestId('conversationListItem-Checkbox')
      fireEvent.click(conversation)

      const moreOptionsButtons = await container.findAllByTestId('message-more-options')
      fireEvent.click(moreOptionsButtons[1])
      const deleteOption = await container.findByTestId('message-delete')
      fireEvent.click(deleteOption)
      expect(window.confirm).toHaveBeenCalled()
    })

    it('should find desktop message list container', () => {
      const container = setup()

      expect(container.queryByTestId('desktop-message-action-header')).toBeInTheDocument()
    })

    describe('URL routing', () => {
      it('should load default URL as inbox Scope', async () => {
        const container = setup()
        await waitForApolloLoading()
        expect(window.location.hash).toBe('#filter=type=inbox')

        const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
        expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')
      })

      it('should respect the initial loading url hash', async () => {
        window.location.hash = '#filter=type=sent'
        const container = setup()
        await waitForApolloLoading()
        expect(window.location.hash).toBe('#filter=type=sent')

        const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
        expect(mailboxDropdown.getAttribute('value')).toBe('Sent')
      })

      describe('scope select', () => {
        it('should update filter if url filter value is updated', async () => {
          const container = setup()
          await waitForApolloLoading()

          let mailboxDropdown = await container.findByLabelText('Mailbox Selection')
          expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')

          window.location.hash = '#filter=type=archived'
          await waitForApolloLoading()

          mailboxDropdown = await container.findByLabelText('Mailbox Selection')
          expect(mailboxDropdown.getAttribute('value')).toBe('Archived')
        })

        it('should update the url correctly if scope filter is changed in UI', async () => {
          const container = setup()
          await waitForApolloLoading()

          expect(window.location.hash).toBe('#filter=type=inbox')

          const mailboxDropdown = await container.findByLabelText('Mailbox Selection')
          fireEvent.click(mailboxDropdown)
          await waitForApolloLoading()

          const option = await container.findByText('Sent')
          fireEvent.click(option)
          await waitForApolloLoading()

          expect(window.location.hash).toBe('#filter=type=sent')
        })

        it('should not update filter if url filter is invalid', async () => {
          const container = setup()
          await waitForApolloLoading()

          let mailboxDropdown = await container.findByLabelText('Mailbox Selection')
          expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')

          window.location.hash = '#filter=type=FAKEFILTER'
          await waitForApolloLoading()

          mailboxDropdown = await container.findByLabelText('Mailbox Selection')
          expect(mailboxDropdown.getAttribute('value')).toBe('Inbox')
        })
      })

      describe('course select', () => {
        it('should set the filter if a valid filter option is given in the initialurl', async () => {
          window.location.hash = '#filter=type=inbox&course=course_195'
          const container = setup()
          await waitForApolloLoading()

          const mailboxDropdown = await container.findByTestId('course-select')
          expect(window.location.hash).toBe('#filter=type=inbox&course=course_195')
          expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool')
        })
        it('should update filter if url filter value is updated', async () => {
          window.location.hash = '#filter=type=inbox'
          const container = setup()
          await waitForApolloLoading()

          let mailboxDropdown = await container.findByTestId('course-select')
          expect(window.location.hash).toBe('#filter=type=inbox')
          expect(mailboxDropdown.getAttribute('value')).toBe('')

          window.location.hash = '#filter=type=inbox&course=course_195'
          await waitForApolloLoading()

          mailboxDropdown = await container.findByTestId('course-select')
          expect(mailboxDropdown.getAttribute('value')).toBe('XavierSchool')
        })
        it('should update the url correctly if scope filter is changed in UI', async () => {
          const container = setup()
          await waitForApolloLoading()

          expect(window.location.hash).toBe('#filter=type=inbox')

          const courseDropdown = await container.findByTestId('course-select')
          fireEvent.click(courseDropdown)
          await waitForApolloLoading()

          const option = await container.findByText('XavierSchool')
          fireEvent.click(option)
          await waitForApolloLoading()

          expect(window.location.hash).toBe('#filter=type=inbox&course=course_195')
        })
        it('should remove the courseFilter if the url filter is invalid', async () => {
          const container = setup()
          await waitForApolloLoading()

          window.location.hash = '#filter=type=inbox&course=FAKE_COURSE'
          await waitForApolloLoading()

          const mailboxDropdown = await container.findByTestId('course-select')
          expect(window.location.hash).toBe('#filter=type=inbox')
          expect(mailboxDropdown.getAttribute('value')).toBe('')
        })
      })
    })
  })

  describe('Mobile', () => {
    beforeAll(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {minWidth: '0px'}
      }))
    })

    it('should find mobile message action header', () => {
      const container = setup()

      expect(container.queryByTestId('mobile-message-action-header')).toBeInTheDocument()
    })
  })
})
