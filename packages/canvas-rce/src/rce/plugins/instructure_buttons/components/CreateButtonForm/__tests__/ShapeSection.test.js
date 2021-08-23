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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DEFAULT_SETTINGS} from '../../../svg/constants'
import {ShapeSection} from '../ShapeSection'

function selectOption(button, option) {
  userEvent.click(
    screen.getByRole('button', {
      name: button
    })
  )
  userEvent.click(
    screen.getByRole('option', {
      name: option
    })
  )
}

describe('<ShapeSection />', () => {
  it('changes the button shape', () => {
    const onChange = jest.fn()
    render(<ShapeSection settings={{...DEFAULT_SETTINGS, shape: 'circle'}} onChange={onChange} />)
    selectOption(/button shape/i, /triangle/i)
    expect(onChange).toHaveBeenCalledWith({shape: 'triangle'})
  })

  it('changes the button size', () => {
    const onChange = jest.fn()
    render(<ShapeSection settings={{...DEFAULT_SETTINGS, size: 'small'}} onChange={onChange} />)
    selectOption(/button size/i, /extra small/i)
    expect(onChange).toHaveBeenCalledWith({size: 'x-small'})
  })
})
