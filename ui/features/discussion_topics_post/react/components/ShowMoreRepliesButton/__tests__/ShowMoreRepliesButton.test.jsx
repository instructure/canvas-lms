/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {ShowMoreRepliesButton} from '../ShowMoreRepliesButton'

const setup = props => {
  return render(<ShowMoreRepliesButton {...props} />)
}

describe('ShowMoreRepliesButton', () => {
  const onClick = jest.fn()

  it('Should show the button text', () => {
    const {queryByText} = setup({buttonText: 'Show older replies'})

    expect(queryByText('Show older replies')).toBeTruthy()
  })

  it('Should be able to click the button', () => {
    const {getByTestId} = setup({onClick, buttonText: 'Click Me'})

    fireEvent.click(getByTestId('show-more-replies-button'))
    expect(onClick.mock.calls.length).toBe(1)
  })

  it('should render with disabled prop', () => {
    const {getByTestId} = setup({onClick, buttonText: 'Click Me', fetchingMoreReplies: true})

    expect(getByTestId('show-more-replies-button').getAttribute('aria-disabled')).toBe('true')
  })
})
