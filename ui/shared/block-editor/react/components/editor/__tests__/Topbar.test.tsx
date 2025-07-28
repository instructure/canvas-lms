/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, useEditor} from '@craftjs/core'

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Topbar, type TopbarProps} from '../Topbar'

const user = userEvent.setup()

const mockUndo = jest.fn()
const mockRedo = jest.fn()
let canUndo = true
let canRedo = true

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        canUndo,
        canRedo,
        actions: {
          history: {
            undo: mockUndo,
            redo: mockRedo,
          },
        },
        query: {
          serialize: () => '{}',
        },
      }
    }),
  }
})

const defaultProps: TopbarProps = {
  toolboxOpen: false,
  onToolboxChange: () => {},
}

const renderComponent = (props: Partial<TopbarProps> = {}) => {
  return render(
    <Editor enabled={true}>
      <Topbar {...defaultProps} {...props} />
    </Editor>,
  )
}

describe('Topbar', () => {
  beforeEach(() => {
    mockUndo.mockClear()
    mockRedo.mockClear()
    canUndo = canRedo = true
  })

  it('renders', () => {
    const {getByText} = renderComponent()

    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByText('Undo')).toBeInTheDocument()
    expect(getByText('Redo')).toBeInTheDocument()
    expect(getByText('Block Toolbox')).toBeInTheDocument()
  })

  it('calls onToolboxChange when Block Toolbox checkbox is clicked', async () => {
    const onToolboxChange = jest.fn()
    const {getByLabelText} = renderComponent({onToolboxChange})

    await user.click(getByLabelText('Block Toolbox').closest('input') as HTMLInputElement)
    expect(onToolboxChange).toHaveBeenCalledWith(true)
  })

  it('opens the preview', async () => {
    const {getByText} = renderComponent()

    await user.click(getByText('Preview').closest('button') as HTMLButtonElement)

    const modal = document.querySelector('[role="dialog"]') as HTMLElement
    expect(modal).toHaveAttribute('aria-label', 'Preview')
  })

  it('calls undo', async () => {
    const {getByText} = renderComponent()

    await user.click(getByText('Undo').closest('button') as HTMLButtonElement)
    expect(mockUndo).toHaveBeenCalled()
  })

  it('calls redo', async () => {
    const {getByText} = renderComponent()

    await user.click(getByText('Redo').closest('button') as HTMLButtonElement)
    expect(mockRedo).toHaveBeenCalled()
  })

  it('disabled redo button when canRedo is false', () => {
    canRedo = false
    const {getByText} = renderComponent()

    expect(getByText('Redo').closest('button')).toBeDisabled()
  })

  it('disabled undo button when canUndo is false', () => {
    canUndo = false
    const {getByText} = renderComponent()

    expect(getByText('Undo').closest('button')).toBeDisabled()
  })
})
