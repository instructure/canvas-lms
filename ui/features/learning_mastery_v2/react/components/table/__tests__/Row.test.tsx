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
import {Row} from '../Row'
import {Cell} from '../Cell'
import {Table} from '@instructure/ui-table'

describe('Row', () => {
  const renderInTable = (ui: React.ReactElement) => {
    return render(
      <Table caption="Test Table">
        <Table.Body>{ui}</Table.Body>
      </Table>,
    )
  }

  it('renders children content', () => {
    renderInTable(
      <Row>
        <Cell>Cell 1</Cell>
        <Cell>Cell 2</Cell>
      </Row>,
    )
    expect(screen.getByText('Cell 1')).toBeInTheDocument()
    expect(screen.getByText('Cell 2')).toBeInTheDocument()
  })

  it('renders as tr element by default', () => {
    renderInTable(
      <Row>
        <Cell>Test</Cell>
      </Row>,
    )
    const rows = screen.getAllByRole('row')
    expect(rows.length).toBeGreaterThan(0)
  })

  it('calls setRef with the element when provided', () => {
    const setRef = vi.fn()
    renderInTable(
      <Row setRef={setRef}>
        <Cell>Test</Cell>
      </Row>,
    )
    expect(setRef).toHaveBeenCalled()
  })
})
