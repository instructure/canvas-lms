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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import BulkEditTable from '../BulkEditTable'

function standardAssignmentData() {
  return [
    {
      id: 'assignment_1',
      name: 'First Assignment',
      can_edit: true,
      all_dates: [
        {
          base: true,
          unlock_at: '2020-03-19T00:00:00Z',
          due_at: '2020-03-20T03:00:00Z',
          lock_at: '2020-04-11T00:00:00Z',
          can_edit: true,
        },
      ],
    },
  ]
}

function assignmentWithEditedOverride() {
  return [
    {
      id: 'assignment_1',
      name: 'First Assignment',
      can_edit: true,
      all_dates: [
        {
          base: true,
          unlock_at: '2020-03-19T00:00:00Z',
          due_at: '2020-03-20T03:00:00Z',
          lock_at: '2020-04-11T00:00:00Z',
          can_edit: true,
        },
        {
          id: 'override_1',
          title: 'Section A',
          unlock_at: '2020-03-19T00:00:00Z',
          due_at: '2020-03-21T03:00:00Z',
          lock_at: '2020-04-11T00:00:00Z',
          can_edit: true,
          original_due_at: '2020-03-20T03:00:00Z',
        },
      ],
    },
  ]
}

describe('BulkEditTable Layout', () => {
  const mockUpdateAssignmentDate = vi.fn()
  const mockSetAssignmentSelected = vi.fn()
  const mockSelectAllAssignments = vi.fn()
  const mockClearOverrideEdits = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('stacked layout', () => {
    beforeEach(() => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: vi.fn().mockImplementation(query => ({
          matches: query.includes('maxWidth'),
          media: query,
          onchange: null,
          addListener: vi.fn(),
          removeListener: vi.fn(),
          addEventListener: vi.fn(),
          removeEventListener: vi.fn(),
          dispatchEvent: vi.fn(),
        })),
      })
    })

    it('shows visible text for Actions column header in stacked layout', () => {
      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      expect(screen.getByText('Actions')).toBeInTheDocument()
    })

    it('shows visible text for Notes column header in stacked layout', () => {
      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      expect(screen.getByText('Notes')).toBeInTheDocument()
    })

    it('handles revert click without errors in stacked layout', async () => {
      const user = userEvent.setup()

      render(
        <BulkEditTable
          assignments={assignmentWithEditedOverride()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      const revertButton = screen.getByRole('button', {name: /revert date changes/i})
      await user.click(revertButton)

      expect(mockClearOverrideEdits).toHaveBeenCalledWith({
        assignmentId: 'assignment_1',
        overrideId: 'override_1',
      })
    })
  })

  describe('fixed layout', () => {
    let matchMediaMock

    beforeEach(() => {
      matchMediaMock = vi.fn().mockImplementation(query => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn((event, handler) => {
          if (event === 'change') {
            setTimeout(() => handler({matches: false}), 0)
          }
        }),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      }))

      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: matchMediaMock,
      })
    })

    it('shows screen reader only text for Actions column header in fixed layout', async () => {
      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      const actionsText = await screen.findByText('Actions')

      expect(actionsText).toHaveAttribute('class', expect.stringContaining('screenReaderContent'))
    })

    it('shows screen reader only text for Notes column header in fixed layout', async () => {
      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      const notesText = await screen.findByText('Notes')

      expect(notesText).toHaveAttribute('class', expect.stringContaining('screenReaderContent'))
    })

    it('handles revert click without errors in fixed layout', async () => {
      const user = userEvent.setup()

      render(
        <BulkEditTable
          assignments={assignmentWithEditedOverride()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )

      const revertButton = screen.getByRole('button', {name: /revert date changes/i})
      await user.click(revertButton)

      expect(mockClearOverrideEdits).toHaveBeenCalledWith({
        assignmentId: 'assignment_1',
        overrideId: 'override_1',
      })
    })
  })
})
