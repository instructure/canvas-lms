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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import {MessageActionButtons} from '../MessageActionButtons'
import {ConversationContext} from '../../../../util/constants'

const createProps = overrides => {
  return {
    isSubmissionComment: false,
    replyDisabled: false,
    archiveDisabled: false,
    deleteDisabled: false,
    settingsDisabled: false,
    shouldRenderMarkAsRead: true,
    shouldRenderMarkAsUnread: true,
    compose: jest.fn(),
    reply: jest.fn(),
    replyAll: jest.fn(),
    archive: jest.fn(),
    delete: jest.fn(),
    markAsUnread: jest.fn(),
    markAsRead: jest.fn(),
    forward: jest.fn(),
    star: jest.fn(),
    ...overrides,
  }
}

describe('MessageActionButtons', () => {
  it('renders all the expected buttons', () => {
    const props = createProps()
    const {getByTestId} = render(<MessageActionButtons {...props} />)

    expect(getByTestId('compose')).toBeInTheDocument()
    expect(getByTestId('reply')).toBeInTheDocument()
    expect(getByTestId('reply-all')).toBeInTheDocument()
    expect(getByTestId('archive')).toBeInTheDocument()
    expect(getByTestId('delete')).toBeInTheDocument()
    expect(getByTestId('settings')).toBeInTheDocument()
  })

  it('uses the correct functions when an action is clicked', () => {
    const props = createProps()
    const {getByTestId, getByText} = render(<MessageActionButtons {...props} />)

    fireEvent.click(getByTestId('compose'))
    expect(props.compose).toHaveBeenCalled()

    fireEvent.click(getByTestId('reply'))
    expect(props.reply).toHaveBeenCalled()

    fireEvent.click(getByTestId('reply-all'))
    expect(props.replyAll).toHaveBeenCalled()

    fireEvent.click(getByTestId('archive'))
    expect(props.archive).toHaveBeenCalled()

    fireEvent.click(getByTestId('delete'))
    expect(props.delete).toHaveBeenCalled()

    fireEvent.click(getByTestId('settings'))
    fireEvent.click(getByText('Mark as unread'))
    expect(props.markAsUnread).toHaveBeenCalled()

    fireEvent.click(getByTestId('settings'))
    fireEvent.click(getByText('Mark as read'))
    expect(props.markAsRead).toHaveBeenCalled()

    fireEvent.click(getByTestId('settings'))
    fireEvent.click(getByText('Mark as unread'))
    expect(props.markAsUnread).toHaveBeenCalled()

    fireEvent.click(getByTestId('settings'))
    fireEvent.click(getByText('Forward'))
    expect(props.forward).toHaveBeenCalled()

    fireEvent.click(getByTestId('settings'))
    fireEvent.click(getByText('Star'))
    expect(props.star).toHaveBeenCalled()
  })

  it('disables specified actions', () => {
    const props = createProps({
      replyDisabled: true,
      archiveDisabled: true,
      deleteDisabled: true,
      settingsDisabled: true,
    })
    const {getByTestId} = render(<MessageActionButtons {...props} />)

    expect(getByTestId('compose').disabled).toBe(false)
    expect(getByTestId('reply').disabled).toBe(true)
    expect(getByTestId('reply-all').disabled).toBe(true)
    expect(getByTestId('archive').disabled).toBe(true)
    expect(getByTestId('delete').disabled).toBe(true)
    expect(getByTestId('settings').disabled).toBe(true)
  })

  it('renders only the reply button when it is a submission comment', () => {
    const props = createProps()
    const {queryByTestId} = render(
      <ConversationContext.Provider value={{isSubmissionCommentsType: true}}>
        <MessageActionButtons {...props} />
      </ConversationContext.Provider>
    )

    expect(queryByTestId('reply')).toBeInTheDocument()
    expect(queryByTestId('compose')).toBe(null)
    expect(queryByTestId('reply-all')).toBe(null)
    expect(queryByTestId('archive')).toBe(null)
    expect(queryByTestId('delete')).toBe(null)
    expect(queryByTestId('settings')).toBe(null)
  })

  it('calls unarchive when unarchive prop exists', async () => {
    const props = createProps({
      unarchive: jest.fn(),
    })

    const {queryByTestId} = render(<MessageActionButtons {...props} />)
    fireEvent.click(queryByTestId('unarchive'))
    expect(props.unarchive).toHaveBeenCalled()
  })

  it('calls archive when unarchive prop exists', async () => {
    const props = createProps()
    const {queryByTestId} = render(<MessageActionButtons {...props} />)
    fireEvent.click(queryByTestId('archive'))
    expect(props.archive).toHaveBeenCalled()
  })
})
