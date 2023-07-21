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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import Button from '../button'

const setup = props => {
  return render(<Button onClick={Function.prototype} {...props} />)
}

describe('canvas_quizzes/components/button', () => {
  it('calls onClick on click', () => {
    const onClick = jest.fn()
    const {getByTestId} = setup({onClick})
    expect(onClick.mock.calls.length).toBe(0)
    fireEvent.click(getByTestId('button'))
    expect(onClick.mock.calls.length).toBe(1)
  })
})
