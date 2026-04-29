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
import {EditMasteryScaleLink, EditMasteryScaleLinkProps} from '../EditMasteryScaleLink'
import {Outcome} from '@canvas/outcomes/react/types/rollup'

describe('EditMasteryScaleLink', () => {
  const createMockOutcome = (overrides = {}): Outcome => ({
    id: '7',
    title: 'Test Outcome',
    calculation_method: 'decaying_average',
    points_possible: 4,
    mastery_points: 3,
    ratings: [],
    context_type: 'Course',
    context_id: '5',
    ...overrides,
  })

  const defaultProps = (props = {}): EditMasteryScaleLinkProps => ({
    outcome: createMockOutcome(),
    accountLevelMasteryScalesFF: false,
    masteryScaleContextType: 'Course',
    masteryScaleContextId: '5',
    ...props,
  })

  describe('when account-level mastery scales FF is OFF', () => {
    it('renders link with outcome_id parameter', () => {
      render(<EditMasteryScaleLink {...defaultProps()} />)
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/5/outcomes?outcome_id=7')
    })

    it('includes group_id parameter when available', () => {
      const outcome = createMockOutcome({group_id: '123'})
      render(<EditMasteryScaleLink {...defaultProps({outcome})} />)
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('href', '/courses/5/outcomes?outcome_id=7&group_id=123')
    })

    it('does not include group_id parameter when not available', () => {
      const outcome = createMockOutcome({group_id: undefined})
      render(<EditMasteryScaleLink {...defaultProps({outcome})} />)
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('href', '/courses/5/outcomes?outcome_id=7')
    })

    it('uses account context when specified', () => {
      render(
        <EditMasteryScaleLink
          {...defaultProps({
            masteryScaleContextType: 'Account',
            masteryScaleContextId: '1',
          })}
        />,
      )
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('href', '/accounts/1/outcomes?outcome_id=7')
    })
  })

  describe('when account-level mastery scales FF is ON', () => {
    it('renders link with mastery_scale hash', () => {
      render(
        <EditMasteryScaleLink {...defaultProps({accountLevelMasteryScalesFF: true})} />,
      )
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/5/outcomes#mastery_scale')
    })

    it('does not include outcome_id or group_id parameters', () => {
      const outcome = createMockOutcome({group_id: '123'})
      render(
        <EditMasteryScaleLink
          {...defaultProps({
            accountLevelMasteryScalesFF: true,
            outcome,
          })}
        />,
      )
      const link = screen.getByTestId('configure-mastery-link')

      const href = link.getAttribute('href')
      expect(href).toBe('/courses/5/outcomes#mastery_scale')
      expect(href).not.toContain('outcome_id')
      expect(href).not.toContain('group_id')
    })

    it('uses account context when specified', () => {
      render(
        <EditMasteryScaleLink
          {...defaultProps({
            accountLevelMasteryScalesFF: true,
            masteryScaleContextType: 'Account',
            masteryScaleContextId: '1',
          })}
        />,
      )
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('href', '/accounts/1/outcomes#mastery_scale')
    })
  })

  describe('link attributes', () => {
    it('opens in a new tab', () => {
      render(<EditMasteryScaleLink {...defaultProps()} />)
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('target', '_blank')
      expect(link).toHaveAttribute('rel', 'noopener noreferrer')
    })

    it('has correct link text', () => {
      render(<EditMasteryScaleLink {...defaultProps()} />)

      expect(screen.getByText('Configure Mastery')).toBeInTheDocument()
    })
  })

  describe('edge cases', () => {
    it('does not render when context type is missing', () => {
      const {container} = render(
        <EditMasteryScaleLink {...defaultProps({masteryScaleContextType: undefined})} />,
      )

      expect(container.firstChild).toBeNull()
    })

    it('does not render when context id is missing', () => {
      const {container} = render(
        <EditMasteryScaleLink {...defaultProps({masteryScaleContextId: undefined})} />,
      )

      expect(container.firstChild).toBeNull()
    })

    it('handles numeric outcome IDs', () => {
      const outcome = createMockOutcome({id: 123 as any})
      render(<EditMasteryScaleLink {...defaultProps({outcome})} />)
      const link = screen.getByTestId('configure-mastery-link')

      expect(link).toHaveAttribute('href', '/courses/5/outcomes?outcome_id=123')
    })
  })
})
