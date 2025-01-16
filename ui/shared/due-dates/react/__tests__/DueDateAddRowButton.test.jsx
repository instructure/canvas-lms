/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DueDateAddRowButton from '../DueDateAddRowButton'

describe('DueDateAddRowButton', () => {
  it('renders the add button when display is true', () => {
    const {getByRole} = render(<DueDateAddRowButton display={true} />)

    const button = getByRole('button', {name: /add new set of due dates/i})
    expect(button).toBeInTheDocument()
    expect(button).toHaveClass('Button', 'Button--add-row')
  })

  it('does not render the button when display is false', () => {
    const {container} = render(<DueDateAddRowButton display={false} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('calls handleAdd when clicked', async () => {
    const handleAdd = jest.fn()
    const {getByRole} = render(<DueDateAddRowButton display={true} handleAdd={handleAdd} />)

    const button = getByRole('button', {name: /add new set of due dates/i})
    await userEvent.click(button)

    expect(handleAdd).toHaveBeenCalledTimes(1)
  })

  it('has proper accessibility attributes', () => {
    const {getByRole} = render(<DueDateAddRowButton display={true} />)

    const button = getByRole('button', {name: /add new set of due dates/i})
    const icon = button.querySelector('.icon-plus')

    expect(icon).toHaveAttribute('role', 'presentation')
    expect(button).toHaveTextContent('Add')
  })
})
