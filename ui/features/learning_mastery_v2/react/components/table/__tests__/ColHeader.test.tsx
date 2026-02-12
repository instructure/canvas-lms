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
import {ColHeader, ColHeaderProps} from '../ColHeader'
import {Table} from '@instructure/ui-table'

describe('ColHeader', () => {
  const renderInTable = (ui: React.ReactElement) => {
    return render(
      <Table caption="Test Table">
        <Table.Head>
          <Table.Row>{ui}</Table.Row>
        </Table.Head>
      </Table>,
    )
  }

  const defaultProps: ColHeaderProps = {
    children: 'Header Content',
  }

  it('renders children content', () => {
    renderInTable(<ColHeader {...defaultProps} />)
    expect(screen.getByText('Header Content')).toBeInTheDocument()
  })

  it('renders as th element by default', () => {
    renderInTable(<ColHeader {...defaultProps} />)
    const header = screen.getByRole('columnheader')
    expect(header.tagName).toBe('TH')
  })

  it('renders as div when isStacked is true', () => {
    renderInTable(<ColHeader {...defaultProps} isStacked={true} />)
    expect(screen.getByTestId('col-header-content')).toBeInTheDocument()
  })

  it('applies col scope to th element', () => {
    renderInTable(<ColHeader {...defaultProps} />)
    const header = screen.getByRole('columnheader')
    expect(header).toHaveAttribute('scope', 'col')
  })

  it('applies sticky position when isSticky is true', () => {
    renderInTable(<ColHeader {...defaultProps} isSticky={true} />)
    const header = screen.getByRole('columnheader')
    expect(header).toHaveStyle({position: 'sticky'})
  })

  it('applies data-cell-id attribute', () => {
    renderInTable(<ColHeader {...defaultProps} data-cell-id="header-0" />)
    const header = screen.getByRole('columnheader')
    expect(header).toHaveAttribute('data-cell-id', 'header-0')
  })

  it('applies grab cursor when isDragging is defined', () => {
    renderInTable(<ColHeader {...defaultProps} isDragging={false} />)
    const header = screen.getByRole('columnheader')
    expect(header).toHaveStyle({cursor: 'grab'})
  })

  it('applies default cursor when isDragging is undefined', () => {
    renderInTable(<ColHeader {...defaultProps} />)
    const header = screen.getByRole('columnheader')
    expect(header).toHaveStyle({cursor: 'default'})
  })

  it('reduces opacity when isDragging is true', () => {
    renderInTable(<ColHeader {...defaultProps} isDragging={true} />)
    const innerDiv = screen.getByTestId('col-header-content')
    expect(innerDiv).toHaveStyle({opacity: '0.5'})
  })

  it('applies full opacity when isDragging is false', () => {
    renderInTable(<ColHeader {...defaultProps} isDragging={false} />)
    const innerDiv = screen.getByTestId('col-header-content')
    expect(innerDiv).toHaveStyle({opacity: '1'})
  })

  it('applies width to inner div', () => {
    renderInTable(<ColHeader {...defaultProps} width="200px" />)
    const innerDiv = screen.getByTestId('col-header-content')
    expect(innerDiv).toHaveStyle({width: '200px'})
  })

  it('calls connectDragSource and connectDropTarget when provided', () => {
    const connectDragSource = vi.fn()
    const connectDropTarget = vi.fn()

    renderInTable(
      <ColHeader
        {...defaultProps}
        connectDragSource={connectDragSource}
        connectDropTarget={connectDropTarget}
      />,
    )

    expect(connectDragSource).toHaveBeenCalled()
    expect(connectDropTarget).toHaveBeenCalled()
  })
})
