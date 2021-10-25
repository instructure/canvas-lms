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
import {MessageDetailHeader} from '../MessageDetailHeader'

describe('MessageDetailHeader', () => {
  it('renders with provided text', () => {
    const props = {text: 'Message Header Text'}
    const {getByText} = render(<MessageDetailHeader {...props} />)
    expect(getByText('Message Header Text')).toBeInTheDocument()
  })

  it('sends the selected option to the provided callback function', () => {
    const handleOptionSelectMock = jest.fn()
    const props = {text: 'Button Test', handleOptionSelect: handleOptionSelectMock}
    const {getByRole, getByText} = render(<MessageDetailHeader {...props} />)

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
