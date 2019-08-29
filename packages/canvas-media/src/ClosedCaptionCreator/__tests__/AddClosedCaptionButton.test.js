/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import AddClosedCaptionButton from '../AddClosedCaptionButton'

function makeProps() {
  return {
    newButtonClick: () => {},
    disabled: true,
    CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER: 'Add Subtitle'
  }
}

describe('AddClosedCaptionButton', () => {
  it('renders normally', () => {
    const {getByText} = render(<AddClosedCaptionButton {...makeProps()} />)
    expect(getByText('Add Subtitle')).toBeInTheDocument()
    expect(getByText('Add Subtitle').closest('button')).toHaveAttribute('disabled')
  })

  it('calls the newButtonClick prop when add subtitle is clicked', () => {
    const callback = jest.fn()
    const {getByText} = render(
      <AddClosedCaptionButton
        newButtonClick={callback}
        disabled={false}
        CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER="Add Subtitle"
      />
    )
    const addButton = getByText('Add Subtitle').closest('button')
    fireEvent.click(addButton)
    expect(callback).toHaveBeenCalledTimes(1)
  })
})
