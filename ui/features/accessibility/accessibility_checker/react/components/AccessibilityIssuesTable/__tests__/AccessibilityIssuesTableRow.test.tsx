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
import {Table} from '@instructure/ui-table'

import {AccessibilityIssuesTableRow} from '../AccessibilityIssuesTableRow'
import {mockScan1} from '../../../../../shared/react/stores/mockData'

const mockMutate = vi.fn()

vi.mock('../../../../../shared/react/hooks/useQueueScanResource', () => ({
  useQueueScanResource: vi.fn(() => ({mutate: mockMutate})),
}))

vi.mock('../Cells/ActionsMenuCell', () => ({
  ActionsMenuCell: () => null,
}))

// canvas.colors.primitives.blue45 resolves to this hex value
const BLUE_45 = '#2B7ABC'

const renderRow = (props: {isSelected?: boolean; isMobile?: boolean} = {}) => {
  const {isSelected = false, isMobile = false} = props
  return render(
    <Table caption="Test table">
      <Table.Body>
        <AccessibilityIssuesTableRow item={mockScan1} isMobile={isMobile} isSelected={isSelected} />
      </Table.Body>
    </Table>,
  )
}

describe('AccessibilityIssuesTableRow', () => {
  beforeEach(() => {
    mockMutate.mockClear()
  })

  it('renders without crashing', () => {
    renderRow({isSelected: false})
    expect(screen.getByTestId('issue-row-1')).toBeInTheDocument()
  })

  it('has data-pendo attribute on resource link', () => {
    renderRow({isSelected: false})
    const link = screen.getByRole('link', {name: 'Test Page 1'})
    expect(link).toHaveAttribute('data-pendo', 'navigate-to-resource-url')
  })

  describe('when isSelected is false', () => {
    it('renders a standard table row without an outline style', () => {
      renderRow({isSelected: false})
      const row = screen.getByTestId('issue-row-1')
      expect(row.style.outline).toBe('')
    })

    it('renders a standard table row without an outlineOffset style', () => {
      renderRow({isSelected: false})
      const row = screen.getByTestId('issue-row-1')
      expect(row.style.outlineOffset).toBe('')
    })
  })

  describe('when isSelected is true', () => {
    it('renders an ActiveTableRow as a <tr> element', () => {
      renderRow({isSelected: true})
      const row = screen.getByTestId('issue-row-1')
      expect(row.tagName).toBe('TR')
    })

    it('applies a blue outline style to the row', () => {
      renderRow({isSelected: true})
      const row = screen.getByTestId('issue-row-1')
      expect(row.style.outline).toBe(`2px solid ${BLUE_45}`)
    })

    it('applies a negative outlineOffset to the row', () => {
      renderRow({isSelected: true})
      const row = screen.getByTestId('issue-row-1')
      expect(row.style.outlineOffset).toBe('-1px')
    })
  })

  describe('when switching from selected to not selected', () => {
    it('removes the outline style when isSelected changes to false', () => {
      const {rerender} = render(
        <Table caption="Test table">
          <Table.Body>
            <AccessibilityIssuesTableRow item={mockScan1} isMobile={false} isSelected={true} />
          </Table.Body>
        </Table>,
      )

      const rowBefore = screen.getByTestId('issue-row-1')
      expect(rowBefore.style.outline).toBe(`2px solid ${BLUE_45}`)

      rerender(
        <Table caption="Test table">
          <Table.Body>
            <AccessibilityIssuesTableRow item={mockScan1} isMobile={false} isSelected={false} />
          </Table.Body>
        </Table>,
      )

      const rowAfter = screen.getByTestId('issue-row-1')
      expect(rowAfter.style.outline).toBe('')
    })

    it('removes the outlineOffset style when isSelected changes to false', () => {
      const {rerender} = render(
        <Table caption="Test table">
          <Table.Body>
            <AccessibilityIssuesTableRow item={mockScan1} isMobile={false} isSelected={true} />
          </Table.Body>
        </Table>,
      )

      rerender(
        <Table caption="Test table">
          <Table.Body>
            <AccessibilityIssuesTableRow item={mockScan1} isMobile={false} isSelected={false} />
          </Table.Body>
        </Table>,
      )

      const row = screen.getByTestId('issue-row-1')
      expect(row.style.outlineOffset).toBe('')
    })
  })
})
