/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {DiscussionTopicNumberInput} from '../DiscussionTopicNumberInput'

const defaultProps = {
  numberInput: 10,
  setNumberInput: () => {},
  numberInputLabel: 'Points Possible',
  numberInputDataTestId: 'points-possible-input'
}

const renderDiscussionTopicNumberInput = () => {
  return render(<DiscussionTopicNumberInput {...defaultProps} />)
}
describe('DiscussionTopicNumberInput', () => {
  it('renders', () => {
    const {getByText} = renderDiscussionTopicNumberInput()
    expect(getByText('Points Possible')).toBeInTheDocument()
  })

  it('does not allow negative values on decrement', () => {
    const mockSetDiscussionTopicNumberInput = jest.fn()
    const {getByTestId} = render(
    <DiscussionTopicNumberInput {...defaultProps} numberInput={0} setNumberInput={mockSetDiscussionTopicNumberInput}/>)

    // Assuming your decrement button has a test id of 'decrement-button', adjust if necessary
    const input = getByTestId('points-possible-input')
    fireEvent.click(input)
    fireEvent.keyDown(input, {keyCode: 40})

    expect(mockSetDiscussionTopicNumberInput).not.toHaveBeenCalledWith(-1)
    expect(mockSetDiscussionTopicNumberInput).toHaveBeenCalledWith(0)
  })
})
