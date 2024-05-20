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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import LoginAttributeSuffixInput from '../components/LoginAttributeSuffixInput'

describe('LoginAttributeSuffixInput', () => {
  const testSuffix = '@example.com'

  const setup = overrides => {
    return render(<LoginAttributeSuffixInput {...overrides} />)
  }

  it('can render without errors', () => {
    const container = setup()
    expect(container.error).toBeFalsy()
  })

  it('calls the provided input handler on input', async () => {
    const handlerMock = jest.fn()
    const container = setup({
      suffixInputHandler: handlerMock,
    })
    await userEvent.type(
      container.getByRole('textbox', {
        name: /login attribute suffix input area/i,
      }),
      testSuffix
    )

    expect(handlerMock).toHaveBeenCalledTimes(testSuffix.length)
  })

  it('renders the provided messages', () => {
    const container = setup({
      messages: [
        {
          text: 'error message!',
          type: 'error',
        },
      ],
    })

    expect(container.getByText(/error message!/i)).toBeInTheDocument()
  })

  it('renders the provided suffix', () => {
    const container = setup({
      loginAttributeSuffix: testSuffix,
    })

    expect(
      container.getByRole('textbox', {
        name: /login attribute suffix input area/i,
      }).value
    ).toBe(testSuffix)
  })
})
