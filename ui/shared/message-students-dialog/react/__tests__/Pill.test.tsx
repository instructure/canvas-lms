// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import Pill from '../Pill'
import {render, waitFor, fireEvent} from '@testing-library/react'
import React from 'react'

function makeProps(overrides) {
  const props = {
    ...overrides,
    onClick: jest.fn().mockResolvedValue({}),
  }
  return props
}

describe('Pill', () => {
  const studentId = 1
  const observerId = 2
  it('renders the user name', () => {
    const props = makeProps({studentId, text: 'Betty Ford'})
    const {findByRole} = render(<Pill {...props} />)

    const button = findByRole('button', {name: 'Betty Ford'})
    waitFor(() => {
      expect(button).toBeInTheDocument()
    })
  })

  it('renders the ADD icon when selected prop is false', () => {
    const props = makeProps({studentId, text: 'Betty Ford'})
    const {getByTestId, queryByTestId} = render(<Pill {...props} />)

    const selectedIcon = queryByTestId('item-selected')
    const unselectedIcon = getByTestId('item-unselected')
    waitFor(() => {
      expect(selectedIcon).not.toBeInTheDocument()
      expect(unselectedIcon).toBeInTheDocument()
    })
  })

  it('renders the X icon when selected prop is true', () => {
    const props = makeProps({studentId, text: 'Betty Ford', selected: true})
    const {getByTestId} = render(<Pill {...props} />)

    const icon = getByTestId('item-selected')
    waitFor(() => {
      expect(icon).toBeInTheDocument()
    })
  })

  it('truncates names with > 14 characters', () => {
    const props = makeProps({studentId, text: 'LongNameLongName', selected: true})
    const {findByRole} = render(<Pill {...props} />)

    const button = findByRole('button', {name: 'LongNameLongN...'})
    waitFor(() => {
      expect(button).toBeInTheDocument()
    })
  })

  it('calls onClick when clicked for student', async () => {
    const props = makeProps({studentId, text: 'Betty Ford', selected: true})
    const {findByRole} = render(<Pill {...props} />)

    const button = await findByRole('button', {name: 'Betty Ford'})
    fireEvent.click(button)

    await waitFor(() => {
      expect(props.onClick).toHaveBeenCalledWith(studentId, null)
    })
  })

  it('calls onClick when clicked for observer', async () => {
    const props = makeProps({studentId, observerId, text: 'Observer 0'})
    const {findByRole} = render(<Pill {...props} />)

    const button = await findByRole('button', {name: 'Observer 0'})
    fireEvent.click(button)

    await waitFor(() => {
      expect(props.onClick).toHaveBeenCalledWith(studentId, observerId)
    })
  })
})
