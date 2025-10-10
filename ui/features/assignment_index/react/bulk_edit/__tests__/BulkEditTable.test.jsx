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

describe('BulkEditTable Layout', () => {
  const mockUpdateAssignmentDate = jest.fn()
  const mockSetAssignmentSelected = jest.fn()
  const mockSelectAllAssignments = jest.fn()
  const mockClearOverrideEdits = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('stacked layout', () => {
    beforeEach(() => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: jest.fn().mockImplementation(query => ({
          matches: query.includes('maxWidth'),
          media: query,
          onchange: null,
          addListener: jest.fn(),
          removeListener: jest.fn(),
          addEventListener: jest.fn(),
          removeEventListener: jest.fn(),
          dispatchEvent: jest.fn(),
        })),
      })

      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )
    })

    it('shows visible text for Actions column header in stacked layout', () => {
      expect(screen.getByText('Actions')).toBeInTheDocument()
    })

    it('shows visible text for Notes column header in stacked layout', () => {
      expect(screen.getByText('Notes')).toBeInTheDocument()
    })
  })

  describe('fixed layout', () => {
    let matchMediaMock

    beforeEach(() => {
      matchMediaMock = jest.fn().mockImplementation(query => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
        addEventListener: jest.fn((event, handler) => {
          if (event === 'change') {
            setTimeout(() => handler({matches: false}), 0)
          }
        }),
        removeEventListener: jest.fn(),
        dispatchEvent: jest.fn(),
      }))

      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: matchMediaMock,
      })

      render(
        <BulkEditTable
          assignments={standardAssignmentData()}
          updateAssignmentDate={mockUpdateAssignmentDate}
          setAssignmentSelected={mockSetAssignmentSelected}
          selectAllAssignments={mockSelectAllAssignments}
          clearOverrideEdits={mockClearOverrideEdits}
        />,
      )
    })

    it('shows screen reader only text for Actions column header in fixed layout', async () => {
      const actionsText = await screen.findByText('Actions')

      expect(actionsText).toHaveAttribute('class', expect.stringContaining('screenReaderContent'))
    })

    it('shows screen reader only text for Notes column header in fixed layout', async () => {
      const notesText = await screen.findByText('Notes')

      expect(notesText).toHaveAttribute('class', expect.stringContaining('screenReaderContent'))
    })
  })
})
