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
import AssignmentDetailsView from '../AssignmentDetailsView'

describe('AssignmentDetailsView', () => {
  describe('Description Heading', () => {
    it('renders Description heading', () => {
      render(<AssignmentDetailsView description="Test description" />)

      expect(screen.getByText('Description')).toBeInTheDocument()
    })
  })

  describe('AssignmentDescription Component', () => {
    it('renders AssignmentDescription with provided description', () => {
      render(<AssignmentDetailsView description="This is the assignment description" />)

      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(screen.getByText('This is the assignment description')).toBeInTheDocument()
    })

    it('renders AssignmentDescription with HTML content', () => {
      const htmlDescription = '<p>This is <strong>bold</strong> text</p>'
      render(<AssignmentDetailsView description={htmlDescription} />)

      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(screen.getByText('bold', {exact: false})).toBeInTheDocument()
    })

    it('renders fallback message when description is empty', () => {
      render(<AssignmentDetailsView description="" />)

      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(
        screen.getByText('No additional details were added for this assignment.'),
      ).toBeInTheDocument()
    })

    it('renders fallback message when description is undefined', () => {
      render(<AssignmentDetailsView />)

      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(
        screen.getByText('No additional details were added for this assignment.'),
      ).toBeInTheDocument()
    })

    it('renders fallback message when description is null', () => {
      render(<AssignmentDetailsView description={undefined} />)

      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(
        screen.getByText('No additional details were added for this assignment.'),
      ).toBeInTheDocument()
    })
  })
})
