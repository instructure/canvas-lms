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

import I18n from 'i18n!conversations_2'
import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {MessageDetailItem} from '../MessageDetailItem'

describe('MessageDetailItem', () => {
  it('renders with provided data', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.'
      },
      contextName: 'Fake Course 1'
    }

    const {getByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(getByText('This is the body text for the message.')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()

    const dateOptions = {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric'
    }

    const createdAt = Intl.DateTimeFormat(I18n.currentLocale(), dateOptions).format(
      new Date(props.conversationMessage.createdAt)
    )
    expect(getByText(createdAt)).toBeInTheDocument()
  })

  it('shows attachment links if they exist', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.',
        attachmentsConnection: {nodes: [{displayName: 'attachment1.jpeg', url: 'testingurl'}]}
      },
      contextName: 'Fake Course 1'
    }

    const {getByText} = render(<MessageDetailItem {...props} />)
    expect(getByText('attachment1.jpeg')).toBeInTheDocument()
  })

  it('sends the selected option to the provided callback function', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        recipients: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}],
        createdAt: 'Tue, 20 Apr 2021 14:31:25 UTC +00:00',
        body: 'This is the body text for the message.'
      },
      contextName: 'Fake Course 1',
      onReply: jest.fn(),
      onReplyAll: jest.fn()
    }

    const {getByTestId, getByText} = render(<MessageDetailItem {...props} />)

    const replyButton = getByTestId('message-reply')
    fireEvent.click(replyButton)
    expect(props.onReply).toHaveBeenCalled()

    const moreOptionsButton = getByTestId('message-more-options')
    fireEvent.click(moreOptionsButton)
    fireEvent.click(getByText('Reply All'))
    expect(props.onReplyAll).toHaveBeenCalled()
  })
})
