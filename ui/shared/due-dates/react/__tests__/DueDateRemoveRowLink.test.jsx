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
import DueDateRemoveRowLink from '../DueDateRemoveRowLink'

describe('DueDateRemoveRowLink', () => {
  it('renders the remove dates button', () => {
    const {getByRole} = render(<DueDateRemoveRowLink handleClick={() => {}} />)
    expect(getByRole('button', {name: 'Remove These Dates'})).toBeInTheDocument()
  })

  it('calls handleClick prop when clicked', async () => {
    const handleClick = jest.fn()
    const {getByRole} = render(<DueDateRemoveRowLink handleClick={handleClick} />)

    const removeButton = getByRole('button', {name: 'Remove These Dates'})
    await userEvent.click(removeButton)

    expect(handleClick).toHaveBeenCalledTimes(1)
  })
})
