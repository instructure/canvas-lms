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
import {RowHeader, RowHeaderProps} from '../RowHeader'
import {Table} from '@instructure/ui-table'

describe('RowHeader', () => {
  const renderInTable = (ui: React.ReactElement) => {
    return render(
      <Table caption="Test Table">
        <Table.Body>
          <Table.Row>{ui}</Table.Row>
        </Table.Body>
      </Table>,
    )
  }

  const defaultProps: RowHeaderProps = {
    children: 'Row Header Content',
  }

  it('renders children content', () => {
    renderInTable(<RowHeader {...defaultProps} />)
    expect(screen.getByText('Row Header Content')).toBeInTheDocument()
  })

  it('renders as th element by default', () => {
    renderInTable(<RowHeader {...defaultProps} />)
    const header = screen.getByRole('rowheader')
    expect(header.tagName).toBe('TH')
  })

  it('renders as div when isStacked is true', () => {
    render(<RowHeader {...defaultProps} isStacked={true} />)
    const header = screen.getByRole('rowheader')
    expect(header.tagName).toBe('DIV')
  })

  it('applies row scope to th element', () => {
    renderInTable(<RowHeader {...defaultProps} />)
    const header = screen.getByRole('rowheader')
    expect(header).toHaveAttribute('scope', 'row')
  })

  it('applies rowheader role when isStacked is true', () => {
    render(<RowHeader {...defaultProps} isStacked={true} />)
    const header = screen.getByRole('rowheader')
    expect(header).toHaveAttribute('role', 'rowheader')
  })

  it('applies sticky position when isSticky is true', () => {
    renderInTable(<RowHeader {...defaultProps} isSticky={true} />)
    const header = screen.getByRole('rowheader')
    expect(header).toHaveStyle({position: 'sticky'})
  })

  it('applies primary background when isSticky is true and no background provided', () => {
    renderInTable(<RowHeader {...defaultProps} isSticky={true} />)
    const header = screen.getByRole('rowheader')
    expect(header).toBeInTheDocument()
  })

  it('applies data-cell-id attribute', () => {
    renderInTable(<RowHeader {...defaultProps} data-cell-id="cell-0-0" />)
    const header = screen.getByRole('rowheader')
    expect(header).toHaveAttribute('data-cell-id', 'cell-0-0')
  })

  it('applies custom background when provided', () => {
    renderInTable(<RowHeader {...defaultProps} background="secondary" />)
    const header = screen.getByRole('rowheader')
    expect(header).toBeInTheDocument()
  })
})
