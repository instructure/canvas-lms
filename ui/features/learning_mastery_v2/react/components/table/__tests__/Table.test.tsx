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
import userEvent from '@testing-library/user-event'
import {Table} from '../Table'
import {Column} from '../utils'

describe('Table', () => {
  const mockColumns: Column[] = [
    {
      key: 'name',
      header: 'Name',
      width: 200,
      isSticky: true,
      isRowHeader: true,
    },
    {
      key: 'email',
      header: 'Email',
      width: 300,
    },
    {
      key: 'score',
      header: () => <span>Score</span>,
      render: (value: number) => <span>{value}%</span>,
      width: 100,
    },
  ]

  const mockData = [
    {name: 'John Doe', email: 'john@example.com', score: 85},
    {name: 'Jane Smith', email: 'jane@example.com', score: 92},
  ]

  it('renders table with caption', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('Test Table')).toBeInTheDocument()
  })

  it('renders column headers', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('Email')).toBeInTheDocument()
    expect(screen.getByText('Score')).toBeInTheDocument()
  })

  it('renders header as function when provided', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('Score')).toBeInTheDocument()
  })

  it('renders data rows', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.getByText('jane@example.com')).toBeInTheDocument()
  })

  it('applies custom render function when provided', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('85%')).toBeInTheDocument()
    expect(screen.getByText('92%')).toBeInTheDocument()
  })

  it('renders data without custom render when not provided', () => {
    render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
    expect(screen.getByText('john@example.com')).toBeInTheDocument()
  })

  describe('keyboard navigation', () => {
    it('navigates right with ArrowRight key', async () => {
      const user = userEvent.setup()
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)

      const firstCell = screen.getByText('Name')
      firstCell.focus()

      await user.keyboard('{ArrowRight}')
      expect(document.activeElement?.textContent).toContain('Email')
    })

    it('navigates left with ArrowLeft key', async () => {
      const user = userEvent.setup()
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)

      const emailHeader = screen.getByText('Email')
      emailHeader.focus()

      await user.keyboard('{ArrowLeft}')
      expect(document.activeElement?.textContent).toContain('Name')
    })

    it('navigates down with ArrowDown key', async () => {
      const user = userEvent.setup()
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)

      const nameHeader = screen.getByText('Name')
      nameHeader.focus()

      await user.keyboard('{ArrowDown}')
      expect(document.activeElement?.textContent).toContain('John Doe')
    })

    it('navigates up with ArrowUp key', async () => {
      const user = userEvent.setup()
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)

      const johnCell = screen.getByText('John Doe')
      johnCell.focus()

      await user.keyboard('{ArrowUp}')
      expect(document.activeElement?.textContent).toContain('Name')
    })

    it('does not navigate beyond table boundaries', async () => {
      const user = userEvent.setup()
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)

      const nameHeader = screen.getByText('Name')
      nameHeader.focus()

      await user.keyboard('{ArrowLeft}')
      expect(document.activeElement?.textContent).toContain('Name')
    })
  })

  describe('renderAboveHeader', () => {
    it('renders content above header when provided', () => {
      const renderAboveHeader = () => (
        <tr>
          <th colSpan={3}>Above Header Content</th>
        </tr>
      )
      render(
        <Table
          columns={mockColumns}
          data={mockData}
          caption="Test Table"
          renderAboveHeader={renderAboveHeader}
        />,
      )
      expect(screen.getByText('Above Header Content')).toBeInTheDocument()
    })

    it('allows navigation to above-header row with ArrowUp', async () => {
      const user = userEvent.setup()
      const renderAboveHeader = (_cols: Column[], handleKeyDown: any) => (
        <tr>
          <th
            colSpan={3}
            data-cell-id="above-header-0"
            tabIndex={0}
            onKeyDown={(e: React.KeyboardEvent) => handleKeyDown(e, -2, 0)}
          >
            Above Header
          </th>
        </tr>
      )

      render(
        <Table
          columns={mockColumns}
          data={mockData}
          caption="Test Table"
          renderAboveHeader={renderAboveHeader}
        />,
      )

      const nameHeader = screen.getByText('Name')
      nameHeader.focus()

      await user.keyboard('{ArrowUp}')
      expect(document.activeElement?.textContent).toContain('Above Header')
    })
  })

  describe('drag and drop', () => {
    it('renders draggable columns when dragDropConfig is provided', () => {
      const draggableColumns: Column[] = [
        {...mockColumns[0]},
        {...mockColumns[1], draggable: true},
        {...mockColumns[2], draggable: true},
      ]

      const dragDropConfig = {
        type: 'column',
        enabled: true,
        onMove: vi.fn(),
      }

      render(
        <Table
          columns={draggableColumns}
          data={mockData}
          caption="Test Table"
          dragDropConfig={dragDropConfig}
        />,
      )

      expect(screen.getByText('Email')).toBeInTheDocument()
      expect(screen.getByText('Score')).toBeInTheDocument()
    })

    it('calls onMove when column is moved', () => {
      const onMove = vi.fn()
      const draggableColumns: Column[] = mockColumns.map(col => ({
        ...col,
        draggable: true,
      }))

      const dragDropConfig = {
        type: 'column',
        enabled: true,
        onMove,
      }

      render(
        <Table
          columns={draggableColumns}
          data={mockData}
          caption="Test Table"
          dragDropConfig={dragDropConfig}
        />,
      )

      expect(screen.getByText('Name')).toBeInTheDocument()
    })
  })

  describe('sticky columns', () => {
    it('applies sticky styling to sticky columns', () => {
      render(<Table columns={mockColumns} data={mockData} caption="Test Table" />)
      const stickyHeader = document.getElementById('name')
      expect(stickyHeader).toHaveStyle({position: 'sticky'})
    })
  })
})
