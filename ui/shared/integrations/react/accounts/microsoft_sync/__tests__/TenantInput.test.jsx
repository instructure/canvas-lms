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
import TenantInput from '../components/TenantInput'

describe('TenantInput', () => {
  const tenant = 'testtenant.com'
  const setup = overrides => {
    return render(<TenantInput {...overrides} />)
  }

  it('renders without errors', () => {
    const container = setup()
    expect(container.error).toBeFalsy()
  })

  it('calls the provided input handler on input', () => {
    const inputHandlerMock = jest.fn()
    const container = setup({
      tenantInputHandler: inputHandlerMock,
    })
    fireEvent.input(
      container.getByRole('textbox', {
        name: /tenant name input area/i,
      }),
      {target: {value: 'testtenant.com'}}
    )

    expect(inputHandlerMock).toHaveBeenCalled()
  })

  it('renders provided error messages', () => {
    const container = setup({
      messages: [
        {
          text: 'error message!',
          type: 'error',
        },
        {
          text: 'hint message!',
          type: 'hint',
        },
      ],
    })

    expect(container.getByText(/error message/i)).toBeInTheDocument()
    expect(container.getByText(/hint message/i)).toBeInTheDocument()
  })

  it('renders the provided tenant', () => {
    const container = setup({
      tenant,
    })

    expect(
      container.getByRole('textbox', {
        name: /tenant name input area/i,
      }).value
    ).toBe(tenant)
  })
})
