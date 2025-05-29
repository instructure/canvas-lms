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
import {AddBlockModal} from '../AddBlockModal'

jest.mock('../AddBlockModal', () => ({
  __esModule: true,
  AddBlockModal: jest.fn(() => <div data-testid="mock-modal" />),
}))

describe('AddBlock', () => {
  it('renders', async () => {
    render(<AddBlock onAddBlock={jest.fn()} />)
    expect(await screen.findByTestId('add-block-heading')).toBeInTheDocument()
    expect(await screen.findByTestId('add-block-button')).toBeInTheDocument()
  })

  it('renders modal with "open" when add button is clicked', async () => {
    const onAddBlockMock = jest.fn()
    render(<AddBlock onAddBlock={onAddBlockMock} />)
    const button = await screen.findByTestId('add-block-button')
    button.click()
    expect(AddBlockModal).toHaveBeenCalledWith(
      expect.objectContaining({open: true}),
      expect.anything(),
    )
  })

  it('renders modal and passes "onAddBlock" method when add button is clicked', async () => {
    const onAddBlockMock = jest.fn()
    render(<AddBlock onAddBlock={onAddBlockMock} />)
    const button = await screen.findByTestId('add-block-button')
    button.click()
    expect(AddBlockModal).toHaveBeenCalledWith(
      expect.objectContaining({onAddBlock: onAddBlockMock}),
      expect.anything(),
    )
  })
})
