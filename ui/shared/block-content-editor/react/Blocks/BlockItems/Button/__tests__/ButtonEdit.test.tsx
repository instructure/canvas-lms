/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {ButtonEdit} from '../ButtonEdit'
import {ButtonData} from '../types'

const mockOpenSettingsTray = vi.fn()
vi.mock('../../../../hooks/useSettingsTray', () => ({
  useSettingsTray: () => ({
    open: mockOpenSettingsTray,
    close: vi.fn(),
  }),
}))

const mockUseNode = vi.fn()
vi.mock('@craftjs/core', async () => ({
  ...await vi.importActual('@craftjs/core'),
  useNode: () => mockUseNode(),
}))

const defaultButtonData: ButtonData = {
  id: 1,
  text: 'Test Button',
  url: 'https://example.com',
  linkOpenMode: 'new-tab',
  primaryColor: '#000000',
  secondaryColor: '#FFFFFF',
  style: 'filled',
}

const defaultProps = {
  ...defaultButtonData,
  isFullWidth: false,
}

const expectedNodeId = 'node-123'

beforeEach(() => {
  vi.clearAllMocks()
  mockUseNode.mockReturnValue({id: expectedNodeId})
})

describe('ButtonEdit', () => {
  it('shows "Opens block settings" tooltip', async () => {
    const user = userEvent.setup()
    render(<ButtonEdit {...defaultProps} />)

    const button = screen.getByRole('button')
    await user.hover(button)
    expect(screen.getByText('Opens block settings')).toBeInTheDocument()
  })

  it('calls openSettingsTray when clicked', async () => {
    const user = userEvent.setup()
    render(<ButtonEdit {...defaultProps} />)

    const button = screen.getByRole('button')
    await user.click(button)
    expect(mockOpenSettingsTray).toHaveBeenCalledWith(expectedNodeId)
  })
})
