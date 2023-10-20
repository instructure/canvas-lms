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
import LoginAttributeSelector from '../components/LoginAttributeSelector'

describe('LoginAttributeSelector', () => {
  const setup = overrides => {
    return render(<LoginAttributeSelector {...overrides} />)
  }

  it('renders without errors', () => {
    const container = setup()

    expect(container.error).toBeFalsy()
  })

  it('calls the specified callback on clicks', () => {
    const changedMock = jest.fn()
    const container = setup({attributeChangedHandler: changedMock})

    fireEvent.click(container.getByRole('combobox', {name: /login attribute selector/i}))
    fireEvent.click(container.getByText(/email/i))

    expect(changedMock).toHaveBeenCalledTimes(1)
  })

  it('renders the specified login attribute', () => {
    const container = setup({selectedLoginAttribute: 'preferred_username'})

    expect(
      container.getByRole('combobox', {
        name: /login attribute selector/i,
      }).value
    ).toMatch(/Unique User ID/i)
  })
})
