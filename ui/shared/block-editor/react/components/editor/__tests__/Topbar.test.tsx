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

const mockUndo = vi.fn()
const mockRedo = vi.fn()
let canUndo = true
let canRedo = true

vi.mock('@craftjs/core', async () => {
  const actual = await vi.importActual('@craftjs/core')
  return {
    ...actual,
    useEditor: vi.fn((selector) => {
      const state = {}
      const query = {
        history: {
          canUndo: () => canUndo,
          canRedo: () => canRedo,
        },
        serialize: () => '{}',
      }

      if (selector) {
        return selector(state, query)
      }

      return {
        canUndo,
        canRedo,
        actions: {
          history: {
            undo: mockUndo,
            redo: mockRedo,
          },
        },
        query,
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

describe.skip('Topbar', () => {
  beforeEach(() => {
    mockUndo.mockClear()
    mockRedo.mockClear()
    canUndo = canRedo = true
  })

  it('renders', () => {
    const {getByText, getByRole} = renderComponent()

    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByRole('button', {name: 'Undo'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Redo'})).toBeInTheDocument()
    expect(getByText('Block Toolbox')).toBeInTheDocument()
  })

  it('calls onToolboxChange when Block Toolbox checkbox is clicked', async () => {
    const onToolboxChange = vi.fn()
    const {getByLabelText} = renderComponent({onToolboxChange})

    await user.click(getByLabelText('Block Toolbox'))
    expect(onToolboxChange).toHaveBeenCalledWith(true)
  })

  it('opens the preview', async () => {
    const {getByRole} = renderComponent()

    await user.click(getByRole('button', {name: 'Preview'}))

    const modal = document.querySelector('[role="dialog"]') as HTMLElement
    expect(modal).toHaveAttribute('aria-label', 'Preview')
  })

  it('calls undo', async () => {
    const {getByRole} = renderComponent()

    await user.click(getByRole('button', {name: 'Undo'}))
    expect(mockUndo).toHaveBeenCalled()
  })

  it('calls redo', async () => {
    const {getByRole} = renderComponent()

    await user.click(getByRole('button', {name: 'Redo'}))
    expect(mockRedo).toHaveBeenCalled()
  })

  it('disabled redo button when canRedo is false', () => {
    canRedo = false
    const {getByRole} = renderComponent()

    expect(getByRole('button', {name: 'Redo'})).toBeDisabled()
  })

  it('disabled undo button when canUndo is false', () => {
    canUndo = false
    const {getByRole} = renderComponent()

    expect(getByRole('button', {name: 'Undo'})).toBeDisabled()
  })
})
