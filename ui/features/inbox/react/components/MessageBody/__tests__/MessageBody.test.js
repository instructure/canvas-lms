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
import {MessageBody} from '../MessageBody'

const createProps = overrides => {
  return {
    onBodyChange: jest.fn(),
    ...overrides,
  }
}

describe('MessageBody', () => {
  it('renders the message body', () => {
    const props = createProps()
    const {getByTestId} = render(<MessageBody {...props} />)
    expect(getByTestId('message-body')).toBeInTheDocument()
  })

  it('uses the onBodyChange prop when the value has changed', () => {
    const props = createProps()
    const {getByTestId} = render(<MessageBody {...props} />)
    const messageBody = getByTestId('message-body')
    fireEvent.change(messageBody, {target: {value: 'howdy'}})
    expect(messageBody.value).toBe('howdy')
    expect(props.onBodyChange).toHaveBeenCalled()
  })

  it('renders a message if provided', () => {
    const props = createProps({
      messages: [
        {
          text: 'Please insert a message body.',
          type: 'error',
        },
      ],
    })
    const {getByText} = render(<MessageBody {...props} />)
    expect(getByText(props.messages[0].text)).toBeInTheDocument()
  })
})
