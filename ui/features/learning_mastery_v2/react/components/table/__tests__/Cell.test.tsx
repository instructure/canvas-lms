/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Cell, CellProps} from '../Cell'
import {Table} from '@instructure/ui-table'

describe('Cell', () => {
  const renderInTable = (ui: React.ReactElement, layout?: 'stacked' | 'fixed' | 'auto') => {
    return render(
      <Table caption="Test Table" layout={layout}>
        <Table.Body>
          <Table.Row>{ui}</Table.Row>
        </Table.Body>
      </Table>,
    )
  }

  const defaultProps: CellProps = {
    children: 'Test Content',
  }

  it('renders children content', () => {
    renderInTable(<Cell {...defaultProps} />)
    expect(screen.getByText('Test Content')).toBeInTheDocument()
  })

  it('renders as td element by default', () => {
    renderInTable(<Cell {...defaultProps} />)
    const cell = screen.getByRole('cell')
    expect(cell.tagName).toBe('TD')
  })

  it('renders as div when table is stacked', () => {
    renderInTable(<Cell {...defaultProps} />, 'stacked')
    const cell = screen.getByRole('cell')
    expect(cell.tagName).toBe('DIV')
  })

  it('adds cell role when table is stacked', () => {
    renderInTable(<Cell {...defaultProps} />, 'stacked')
    const cell = screen.getByRole('cell')
    expect(cell).toHaveAttribute('role', 'cell')
  })

  it('applies width when provided', () => {
    renderInTable(<Cell {...defaultProps} width="200px" />)
    const cell = screen.getByRole('cell')
    expect(cell).toHaveStyle({width: '200px'})
  })

  it('applies sticky position when isSticky is true', () => {
    renderInTable(<Cell {...defaultProps} isSticky={true} />)
    const cell = screen.getByRole('cell')
    expect(cell).toHaveStyle({position: 'sticky'})
  })

  it('applies primary background when isSticky is true and no background provided', () => {
    renderInTable(<Cell {...defaultProps} isSticky={true} />)
    const cell = screen.getByRole('cell')
    expect(cell).toBeInTheDocument()
  })

  it('applies custom id when provided', () => {
    renderInTable(<Cell {...defaultProps} id="custom-cell-id" />)
    const cell = screen.getByRole('cell')
    expect(cell).toHaveAttribute('id', 'custom-cell-id')
  })

  it('applies custom background over default when isSticky is true', () => {
    renderInTable(<Cell {...defaultProps} isSticky={true} background="secondary" />)
    const cell = screen.getByRole('cell')
    expect(cell).toBeInTheDocument()
  })
})
