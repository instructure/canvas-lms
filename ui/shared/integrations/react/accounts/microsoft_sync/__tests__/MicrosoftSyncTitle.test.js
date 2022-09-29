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
import MicrosoftSyncTitle from '../components/MicrosoftSyncTitle'

describe('MicrosoftSyncTitle', () => {
  const setup = overrides => {
    return render(<MicrosoftSyncTitle {...overrides} />)
  }

  it('renders without errors', () => {
    const container = setup()
    expect(container.error).toBeFalsy()
  })

  it('calls the specified callback when clicked', () => {
    const clickMock = jest.fn()
    const container = setup({handleClick: clickMock})

    fireEvent.click(
      container.getByRole('checkbox', {
        name: /allows syncing of canvas course members to a microsoft team/i,
      })
    )

    expect(clickMock).toHaveBeenCalledTimes(1)
  })

  it('renders as checked or unchecked based on props', () => {
    const container = setup({syncEnabled: true, handleClick: jest.fn()})

    expect(
      container.getByRole('checkbox', {
        name: /allows syncing of canvas course members to a microsoft team/i,
      }).checked
    ).toBeTruthy()
  })

  it('disables the checkbox according to props', () => {
    const container = setup({interactionDisabled: true})
    expect(
      container.getByRole('checkbox', {
        name: /allows syncing of canvas course members to a microsoft team/i,
      }).disabled
    ).toBeTruthy()
  })
})
