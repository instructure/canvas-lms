/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import BlueprintSidebar from '../BlueprintSidebar'

describe('BlueprintSidebar', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  test('renders the BlueprintSidebar component', () => {
    const {container} = render(<BlueprintSidebar />)
    expect(container.querySelector('.bcs__wrapper')).toBeInTheDocument()
  })

  test('clicking open button opens the tray', async () => {
    const {getByRole} = render(<BlueprintSidebar />)
    const button = getByRole('button', {name: 'Open Blueprint Sidebar'})
    const user = userEvent.setup({delay: null})

    await user.click(button)

    // Run all timers to completion for the tray animation
    jest.runAllTimers()

    await waitFor(() => {
      const tray = document.querySelector('[role="dialog"][aria-label="Blueprint Settings"]')
      expect(tray).toBeInTheDocument()
    })
  })

  test('clicking close button closes the tray', async () => {
    const {getByRole} = render(<BlueprintSidebar />)
    const openButton = getByRole('button', {name: 'Open Blueprint Sidebar'})
    const user = userEvent.setup({delay: null})

    // Open the tray first
    await user.click(openButton)
    jest.runAllTimers()

    await waitFor(() => {
      const tray = document.querySelector('[role="dialog"][aria-label="Blueprint Settings"]')
      expect(tray).toBeInTheDocument()
    })

    // Now close it
    const closeButton = getByRole('button', {name: 'Close sidebar'})
    await user.click(closeButton)
    jest.runAllTimers()

    await waitFor(() => {
      const tray = document.querySelector('[role="dialog"][aria-label="Blueprint Settings"]')
      expect(tray).not.toBeInTheDocument()
    })
  })
})
