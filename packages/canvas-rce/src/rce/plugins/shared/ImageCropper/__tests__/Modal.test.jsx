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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import {ImageCropperModal} from '../Modal'
import userEvent from '@testing-library/user-event'

describe('ImageCropperModal', () => {
  let props

  const renderComponent = (overrides = {}) => {
    return render(<ImageCropperModal {...props} {...overrides} />)
  }

  beforeEach(() => {
    props = {
      open: true,
      onSubmit: jest.fn(),
      onClose: jest.fn(),
      image: 'data:image/png;base64,asdfasdfjksdf==',
      trayDispatch: jest.fn(),
    }
  })

  beforeAll(() => {
    global.fetch = jest.fn().mockResolvedValue({
      blob: () => Promise.resolve(new Blob(['somedata'], {type: 'image/svg+xml'})),
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the message', () => {
    renderComponent({message: 'Banana'})
    expect(screen.getByTestId('alert-message')).toBeInTheDocument()
    expect(screen.getByText(/banana/i)).toBeInTheDocument()
  })

  it("doesn't render the message", () => {
    renderComponent()
    expect(screen.queryByTestId('alert-message')).not.toBeInTheDocument()
  })

  it('calls onSubmit function', async () => {
    renderComponent()
    const button = screen.getByRole('button', {name: /save/i})
    await userEvent.click(button)
    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalled()
    })
  })

  it('calls onClose function', async () => {
    renderComponent()
    const button = screen.getByRole('button', {name: /save/i})
    await userEvent.click(button)
    await waitFor(() => {
      expect(props.onClose).toHaveBeenCalled()
    })
  })

  it('call onSubmit function with correct args', async () => {
    renderComponent({shape: 'circle'})
    const button = screen.getByRole('button', {name: /save/i})
    await userEvent.click(button)
    await waitFor(() => {
      expect(props.onSubmit).toHaveBeenCalledWith({
        rotation: 0,
        scaleRatio: 1,
        shape: 'circle',
        translateX: 0,
        translateY: 0,
      })
    })
  })
})
