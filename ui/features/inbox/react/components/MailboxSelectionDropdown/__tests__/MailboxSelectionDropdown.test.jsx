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
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {MailboxSelectionDropdown} from '../MailboxSelectionDropdown'

describe('MailboxSelectionDropdown', () => {
  it('renders', () => {
    const {getByTitle} = render(
      <MailboxSelectionDropdown onSelect={Function.prototype} activeMailbox="inbox" />
    )
    expect(getByTitle('Inbox')).not.toBeNull()
  })

  it('passes selection type to callback', () => {
    global.event = undefined
    const mockCallback = jest.fn()
    const {container, getByText} = render(
      <MailboxSelectionDropdown onSelect={mockCallback} activeMailbox="inbox" />
    )
    const input = container.querySelector('input')
    fireEvent.click(input)
    const unread = getByText('Unread')
    fireEvent.click(unread)
    expect(mockCallback.mock.calls.length).toBe(1)
    expect(mockCallback.mock.calls[0][0]).toBe('unread')
  })

  it('should respect activeMailbox prop', () => {
    global.event = undefined
    const {container} = render(
      <MailboxSelectionDropdown onSelect={() => {}} activeMailbox="unread" />
    )
    const input = container.querySelector('input')
    expect(input.value).toBe('Unread')
  })
})
