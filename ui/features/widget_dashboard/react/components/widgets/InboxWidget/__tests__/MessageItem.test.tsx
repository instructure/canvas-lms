/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {render, screen} from '@testing-library/react'
import MessageItem from '../MessageItem'
import type {InboxMessage} from '../../../../types'

const mockMessage: InboxMessage = {
  id: '1',
  subject: 'Test Message',
  lastMessageAt: '2025-12-08T10:00:00Z',
  messagePreview: 'This is a test message',
  workflowState: 'unread',
  conversationUrl: '/conversations/1',
  participants: [
    {
      id: 'user1',
      name: 'John Doe',
      avatarUrl: 'https://example.com/avatar.jpg',
    },
  ],
}

describe('MessageItem', () => {
  it('renders message information correctly', () => {
    render(<MessageItem message={mockMessage} />)

    expect(screen.getByText('Test Message')).toBeInTheDocument()
    expect(screen.getByText('This is a test message')).toBeInTheDocument()
    expect(screen.getByText('John Doe')).toBeInTheDocument()
  })

  it('displays sender avatar', () => {
    render(<MessageItem message={mockMessage} />)

    const avatar = screen.getByText('John Doe').closest('div')?.querySelector('img')
    expect(avatar).toBeInTheDocument()
  })

  it('handles message with no participants', () => {
    const messageWithoutParticipants = {...mockMessage, participants: []}
    render(<MessageItem message={messageWithoutParticipants} />)

    expect(screen.getByText('Unknown Sender')).toBeInTheDocument()
  })
})
