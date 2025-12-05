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
import {SpeedGraderButton, SpeedGraderButtonProps} from '../SpeedGraderButton'

describe('SpeedGraderButton', () => {
  const defaultProps: SpeedGraderButtonProps = {
    courseId: '123',
    assignmentId: '456',
    studentId: '789',
    disabled: false,
  }

  it('renders SpeedGrader button', () => {
    render(<SpeedGraderButton {...defaultProps} />)
    expect(screen.getByRole('link', {name: /SpeedGrader/i})).toBeInTheDocument()
  })

  it('generates correct URL with student ID', () => {
    render(<SpeedGraderButton {...defaultProps} />)
    const link = screen.getByRole('link', {name: /SpeedGrader/i})
    expect(link).toHaveAttribute(
      'href',
      '/courses/123/gradebook/speed_grader?assignment_id=456&student_id=789',
    )
  })

  it('generates correct URL without student ID', () => {
    render(<SpeedGraderButton {...defaultProps} studentId={undefined} />)
    const link = screen.getByRole('link', {name: /SpeedGrader/i})
    expect(link).toHaveAttribute('href', '/courses/123/gradebook/speed_grader?assignment_id=456')
  })

  it('opens in new tab', () => {
    render(<SpeedGraderButton {...defaultProps} />)
    const link = screen.getByRole('link', {name: /SpeedGrader/i})
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener')
  })
})
