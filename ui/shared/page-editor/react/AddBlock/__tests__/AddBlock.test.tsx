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

import {render, screen} from '@testing-library/react'
import {AddBlock} from '../AddBlock'

const openMock = jest.fn()
jest.mock('../../PageEditorContext', () => ({
  __esModule: true,
  usePageEditorContext: jest.fn(() => ({
    addBlockModal: {
      open: openMock,
    },
  })),
}))

jest.mock('../../hooks/useAddNode', () => ({
  useAddNode: jest.fn(),
}))

describe('AddBlock', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders', async () => {
    render(<AddBlock />)
    expect(await screen.findByTestId('add-block-heading')).toBeInTheDocument()
    expect(await screen.findByTestId('add-block-button')).toBeInTheDocument()
  })

  it('renders modal with "open" when add button is clicked', async () => {
    render(<AddBlock />)
    const button = await screen.findByTestId('add-block-button')
    button.click()
    expect(openMock).toHaveBeenCalled()
  })
})
