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
import AIExperiencesEmptyState from '../AIExperiencesEmptyState'

describe('AIExperiencesEmptyState', () => {
  const mockOnCreateNew = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('Teacher view (canManage = true)', () => {
    it('renders the spaceman image', () => {
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      const image = screen.getByAltText('Spaceman floating in space')
      expect(image).toBeInTheDocument()
      expect(image).toHaveAttribute('src', '/images/spaceman.png')
    })

    it('renders the teacher empty state heading', () => {
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      expect(screen.getByText('No AI experiences created yet.')).toBeInTheDocument()
    })

    it('renders the teacher empty state description', () => {
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      expect(
        screen.getByText('Click the Create New button to start building your first AI experience.'),
      ).toBeInTheDocument()
    })

    it('renders the Create new button', () => {
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      expect(screen.getByText('Create new')).toBeInTheDocument()
    })

    it('calls onCreateNew when Create new button is clicked', async () => {
      const user = userEvent.setup()
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      const createButton = screen.getByText('Create new').closest('button')
      await user.click(createButton!)

      expect(mockOnCreateNew).toHaveBeenCalledTimes(1)
    })

    it('has the plus icon on the Create new button', () => {
      render(<AIExperiencesEmptyState canManage={true} onCreateNew={mockOnCreateNew} />)

      const createButton = screen.getByText('Create new').closest('button')
      const icon = createButton!.querySelector('svg')

      expect(icon).toBeInTheDocument()
    })
  })

  describe('Student view (canManage = false)', () => {
    it('renders the spaceman image', () => {
      render(<AIExperiencesEmptyState canManage={false} onCreateNew={mockOnCreateNew} />)

      const image = screen.getByAltText('Spaceman floating in space')
      expect(image).toBeInTheDocument()
      expect(image).toHaveAttribute('src', '/images/spaceman.png')
    })

    it('renders the student empty state heading', () => {
      render(<AIExperiencesEmptyState canManage={false} onCreateNew={mockOnCreateNew} />)

      expect(screen.getByText('No AI experiences available yet.')).toBeInTheDocument()
    })

    it('renders the student empty state description', () => {
      render(<AIExperiencesEmptyState canManage={false} onCreateNew={mockOnCreateNew} />)

      expect(
        screen.getByText('Your instructor has not published any AI experiences yet.'),
      ).toBeInTheDocument()
    })

    it('does not render the Create new button', () => {
      render(<AIExperiencesEmptyState canManage={false} onCreateNew={mockOnCreateNew} />)

      expect(screen.queryByText('Create new')).not.toBeInTheDocument()
    })

    it('does not show teacher-specific messaging', () => {
      render(<AIExperiencesEmptyState canManage={false} onCreateNew={mockOnCreateNew} />)

      expect(screen.queryByText('No AI experiences created yet.')).not.toBeInTheDocument()
      expect(
        screen.queryByText(
          'Click the Create New button to start building your first AI experience.',
        ),
      ).not.toBeInTheDocument()
    })
  })
})
