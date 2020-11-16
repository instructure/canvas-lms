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
import {MessageListItem} from '../MessageListItem'

describe('MessageListItem', () => {
  const createProps = overrides => {
    return {
      conversation: {
        subject: 'This is the subject line',
        participants: [{name: 'Bob Barker'}, {name: 'Sally Ford'}, {name: 'Russel Franks'}],
        conversationMessages: [
          {
            author: {name: 'Bob Barker'},
            participants: [{name: 'Bob Barker'}, {name: 'Sally Ford'}, {name: 'Russel Franks'}],
            created_at: 'November 5, 2020 at 2:25pm',
            body: 'This is the body text for the message.'
          },
          {
            author: {name: 'Sally Ford'},
            participants: [{name: 'Sally Ford'}, {name: 'Bob Barker'}, {name: 'Russel Franks'}],
            created_at: 'November 4, 2020 at 2:25pm',
            body: 'This is the body text for the message.'
          }
        ]
      },
      isUnread: false,
      onSelect: jest.fn(),
      onOpen: jest.fn(),
      onStar: jest.fn(),
      ...overrides
    }
  }

  it('calls the onSelect callback with the new state', () => {
    const onSelectMock = jest.fn()

    const props = createProps({onSelect: onSelectMock})

    const {getByRole} = render(<MessageListItem {...props} />)

    const checkbox = getByRole('checkbox')
    fireEvent.click(checkbox)
    expect(onSelectMock).toHaveBeenLastCalledWith(true)
    fireEvent.click(checkbox)
    expect(onSelectMock).toHaveBeenLastCalledWith(false)
  })

  it('calls onOpen when the message is clicked', () => {
    const onOpenMock = jest.fn()

    const props = createProps({onOpen: onOpenMock})

    const {getByText} = render(<MessageListItem {...props} />)

    const subjectLine = getByText('This is the subject line')
    fireEvent.click(subjectLine)
    expect(onOpenMock).toHaveBeenCalled()
  })

  it('shows and hides the star button correctly', () => {
    const onStarMock = jest.fn()

    const props = createProps({onStar: onStarMock})

    const {queryByTestId, getByText} = render(<MessageListItem {...props} />)

    // star not shown by default
    expect(queryByTestId('visible-star')).not.toBeInTheDocument()
    // star shown when message is moused over
    const subjectLine = getByText('This is the subject line')
    fireEvent.mouseOver(subjectLine)
    expect(queryByTestId('visible-star')).toBeInTheDocument()

    fireEvent.click(queryByTestId('visible-star'))
    expect(onStarMock).toHaveBeenLastCalledWith(true)
    // star always shows if selected
    fireEvent.mouseOut(subjectLine)
    expect(queryByTestId('visible-star')).toBeInTheDocument()
  })

  it('renders the unread badge when the conversation is unread', () => {
    const props = createProps({isUnread: true})

    const {getByText} = render(<MessageListItem {...props} />)

    expect(getByText('Unread')).toBeInTheDocument()
  })
})
