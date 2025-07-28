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
import {render} from '@testing-library/react'
import {ToolbarAlignment} from '../toolbar/ToolbarAlignment'

describe('ToolbarAlignment', () => {
  it('renders', () => {
    const {getByText} = render(<ToolbarAlignment onSave={jest.fn()} />)
    expect(getByText('Alignment Options')).toBeInTheDocument()
  })

  it('shows the popup when the button is clicked', () => {
    const {getByText, queryByText} = render(
      <ToolbarAlignment
        layout="row"
        alignment="start"
        verticalAlignment="start"
        onSave={jest.fn()}
      />,
    )
    getByText('Alignment Options').closest('button')?.click()
    expect(getByText('Orientation')).toBeInTheDocument()
    expect(getByText('Alignment')).toBeInTheDocument()
    expect(getByText('Placement')).toBeInTheDocument()
    expect(queryByText('Reset Default Alignment')).not.toBeInTheDocument()
    const checkedItems = document.querySelectorAll('[aria-checked="true"]')
    expect(checkedItems[0].textContent).toContain('Align Horizontally')
    expect(checkedItems[1].textContent).toContain('Align to start')
    expect(checkedItems[2].textContent).toContain('Align to top')
  })

  it('checks the current alignment', () => {
    const {getByText} = render(
      <ToolbarAlignment
        layout="column"
        alignment="center"
        verticalAlignment="end"
        onSave={jest.fn()}
      />,
    )
    getByText('Alignment Options').closest('button')?.click()
    const checkedItems = document.querySelectorAll('[aria-checked="true"]')
    expect(checkedItems[0].textContent).toContain('Align Vertically')
    expect(checkedItems[1].textContent).toContain('Align to center')
    expect(checkedItems[2].textContent).toContain('Align to bottom')
  })

  it('shows the reset button when the alignment is not the default', () => {
    const {getByText} = render(<ToolbarAlignment alignment="center" onSave={jest.fn()} />)
    getByText('Alignment Options').closest('button')?.click()
    getByText('Align Horizontally').click()
    expect(getByText('Reset Default Alignment')).toBeInTheDocument()
  })

  it('hides the reset button once it is clicked', () => {
    const {getByText, queryByText} = render(
      <ToolbarAlignment verticalAlignment="center" onSave={jest.fn()} />,
    )
    getByText('Alignment Options').closest('button')?.click()
    expect(getByText('Reset Default Alignment')).toBeInTheDocument()
    getByText('Reset Default Alignment').click()
    expect(queryByText('Reset Default Alignment')).not.toBeInTheDocument()
  })

  it('resets the menu state once the reset button is clicked', () => {
    const {getByText} = render(
      <ToolbarAlignment
        layout="column"
        alignment="center"
        verticalAlignment="end"
        onSave={jest.fn()}
      />,
    )
    getByText('Alignment Options').closest('button')?.click()

    const checkedMenuItems = document.querySelectorAll('[aria-checked="true"]')
    expect(checkedMenuItems[0].textContent).toContain('Align Vertically')
    expect(checkedMenuItems[1].textContent).toContain('Align to center')
    expect(checkedMenuItems[2].textContent).toContain('Align to bottom')

    getByText('Reset Default Alignment').click()
    const checkedMenuItems2 = document.querySelectorAll('[aria-checked="true"]')
    expect(checkedMenuItems2[0].textContent).toContain('Align Horizontally')
    expect(checkedMenuItems2[1].textContent).toContain('Align to start')
    expect(checkedMenuItems2[2].textContent).toContain('Align to top')
  })
})
