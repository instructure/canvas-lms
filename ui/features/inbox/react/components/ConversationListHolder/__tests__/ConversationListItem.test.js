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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {ConversationListItem} from '../ConversationListItem'
import {responsiveQuerySizes} from '../../../../util/utils'
import {SubmissionComment} from '../../../../graphql/SubmissionComment'

jest.mock('../../../../util/utils', () => ({
  ...jest.requireActual('../../../../util/utils'),
  responsiveQuerySizes: jest.fn()
}))

const submissionsCommentsMock = () => {
  return {
    _id: 1,
    subject: 'XavierSchool - This is an Assignment',
    lastMessageCreatedAt: '2022-02-15T06:50:54-07:00',
    lastMessageContent: 'Hey!',
    participantString: 'Hank Mccoy',
    messages: [SubmissionComment.mock(), SubmissionComment.mock(), SubmissionComment.mock()]
  }
}

describe('ConversationListItem', () => {
  const createProps = overrides => {
    return {
      conversation: {
        _id: '1',
        workflowState: 'unread',
        subject: 'This is the subject line',
        lastMessageCreatedAt: 'November 5, 2020 at 2:25pm',
        lastMessageContent: 'This is the body text for the message.',
        participantString: 'Bob Barker, Sally Ford, Russel Franks',
        messages: [
          {
            author: {name: 'Bob Barker'},
            conversationParticipantsConnection: {
              nodes: [
                [
                  {user: {name: 'Bob Barker'}},
                  {user: {name: 'Sally Ford'}},
                  {user: {name: 'Russel Franks'}}
                ]
              ]
            },
            createdAt: 'November 5, 2020 at 2:25pm',
            body: 'This is the body text for the message.'
          },
          {
            author: {name: 'Sally Ford'},
            conversationParticipantsConnection: {
              nodes: [
                {user: {name: 'Sally Ford'}},
                {user: {name: 'Bob Barker'}},
                {user: {name: 'Russel Franks'}}
              ]
            },
            createdAt: 'November 4, 2020 at 2:25pm',
            body: 'This is the body text for the message.'
          }
        ],
        participants: [
          {user: {name: 'Bob Barker'}},
          {user: {name: 'Sally Ford'}},
          {user: {name: 'Russel Franks'}}
        ]
      },
      isUnread: false,
      onSelect: jest.fn(),
      onOpen: jest.fn(),
      onStar: jest.fn(),
      ...overrides
    }
  }

  beforeAll(() => {
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

  describe('behavior', () => {
    it('calls the onSelect callback with the new state', () => {
      const onSelectMock = jest.fn()

      const props = createProps({onSelect: onSelectMock})

      const {getByRole} = render(<ConversationListItem {...props} />)

      const checkbox = getByRole('checkbox')
      fireEvent.click(checkbox)
      expect(onSelectMock).toHaveBeenCalled()
      expect(checkbox.checked).toBe(true)
      fireEvent.click(checkbox)
      expect(onSelectMock).toHaveBeenCalled()
      expect(checkbox.checked).toBe(false)
    })

    it('calls onOpen when the conversation is clicked', () => {
      const onOpenMock = jest.fn()

      const props = createProps({onOpen: onOpenMock})

      const {getByText} = render(<ConversationListItem {...props} />)

      const subjectLine = getByText('This is the subject line')
      fireEvent.click(subjectLine)
      expect(onOpenMock).toHaveBeenCalled()
    })

    it('shows and hides the star button correctly', () => {
      const onStarMock = jest.fn()

      const props = createProps({onStar: onStarMock})

      const {queryByTestId, getByText} = render(<ConversationListItem {...props} />)

      // star not shown by default
      expect(queryByTestId('visible-star')).not.toBeInTheDocument()
      // star shown when conversation is moused over
      const subjectLine = getByText('This is the subject line')
      fireEvent.mouseOver(subjectLine)
      expect(queryByTestId('visible-star')).toBeInTheDocument()

      fireEvent.click(queryByTestId('visible-star'))
      expect(onStarMock).toHaveBeenLastCalledWith(true, props.conversation._id)
    })

    it('renders the unread badge when the conversation is unread', () => {
      const props = createProps({isUnread: true})

      const container = render(<ConversationListItem {...props} />)

      expect(container.getByText('Unread')).toBeInTheDocument()
      expect(container.getByTestId('unread-badge')).toBeInTheDocument()
    })

    it('renders the read badge when the conversation is read', () => {
      const props = createProps()

      const container = render(<ConversationListItem {...props} />)

      expect(container.getByText('Read')).toBeInTheDocument()
      expect(container.getByTestId('read-badge')).toBeInTheDocument()
    })

    it('update read state called with correct parameters', () => {
      const changeReadState = jest.fn()

      const props = createProps({readStateChangeConversationParticipants: changeReadState})

      const container = render(<ConversationListItem {...props} />)

      const unreadBadge = container.queryByTestId('read-badge')
      fireEvent.click(unreadBadge)

      expect(changeReadState).toHaveBeenCalledWith({
        variables: {
          conversationIds: ['1'],
          workflowState: 'unread'
        }
      })
    })
  })

  describe('responsiveness', () => {
    describe('tablet', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          tablet: {maxWidth: '67'}
        }))
      })

      it('should emit correct test id for tablet', async () => {
        const props = createProps({})
        const container = render(<ConversationListItem {...props} />)
        const listItem = await container.findByTestId('list-item-tablet')
        expect(listItem).toBeTruthy()
      })
    })

    describe('desktop', () => {
      beforeEach(() => {
        responsiveQuerySizes.mockImplementation(() => ({
          desktop: {minWidth: '768'}
        }))
      })

      it('should emit correct test id for desktop', async () => {
        const props = createProps({})
        const container = render(<ConversationListItem {...props} />)
        const listItem = await container.findByTestId('list-item-desktop')
        expect(listItem).toBeTruthy()
      })
    })
  })

  describe('submission comments', () => {
    it('renders subject', () => {
      const props = createProps({
        conversation: submissionsCommentsMock()
      })
      const {getByText} = render(<ConversationListItem {...props} />)

      expect(getByText('XavierSchool - This is an Assignment')).toBeTruthy()
    })

    it('renders create date', () => {
      const props = createProps({
        conversation: submissionsCommentsMock()
      })
      const {getByText} = render(<ConversationListItem {...props} />)

      expect(getByText('Feb 15, 2022')).toBeTruthy()
    })

    it('renders author', () => {
      const props = createProps({
        conversation: submissionsCommentsMock()
      })
      const {getByText} = render(<ConversationListItem {...props} />)

      expect(getByText('Hank Mccoy')).toBeTruthy()
    })

    it('renders comment', () => {
      const props = createProps({
        conversation: submissionsCommentsMock()
      })
      const {getByText} = render(<ConversationListItem {...props} />)

      expect(getByText('Hey!')).toBeTruthy()
    })
  })
})
