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
import {MessageDetailItem} from '../MessageDetailItem'

describe('MessageDetailItem', () => {
  it('renders with provided data', () => {
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        participants: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}],
        created_at: 'November 10, 2020 at 5:48pm',
        body: 'This is the body text for the message.'
      },
      context: {name: 'Fake Course 1'}
    }

    const {getByText} = render(<MessageDetailItem {...props} />)

    expect(getByText('Tom Thompson')).toBeInTheDocument()
    expect(getByText(', Billy Harris')).toBeInTheDocument()
    expect(getByText('November 10, 2020 at 5:48pm')).toBeInTheDocument()
    expect(getByText('This is the body text for the message.')).toBeInTheDocument()
    expect(getByText('Fake Course 1')).toBeInTheDocument()
  })

  it('sends the selected option to the provided callback function', () => {
    const handleOptionSelectMock = jest.fn()
    const props = {
      conversationMessage: {
        author: {name: 'Tom Thompson'},
        participants: [{name: 'Tom Thompson'}, {name: 'Billy Harris'}],
        created_at: 'November 10, 2020 at 5:48pm',
        body: 'This is the body text for the message.'
      },
      context: {name: 'Fake Course 1'},
      handleOptionSelect: handleOptionSelectMock
    }

    const {getByRole, getByText} = render(<MessageDetailItem {...props} />)

    const replyButton = getByRole(
      (role, element) => role === 'button' && element.textContent === 'Reply'
    )
    fireEvent.click(replyButton)
    expect(handleOptionSelectMock).toHaveBeenLastCalledWith('reply')

    const moreOptionsButton = getByRole(
      (role, element) => role === 'button' && element.textContent === 'More options'
    )
    fireEvent.click(moreOptionsButton)
    fireEvent.click(getByText('Forward'))
    expect(handleOptionSelectMock).toHaveBeenLastCalledWith('forward')
  })
})
