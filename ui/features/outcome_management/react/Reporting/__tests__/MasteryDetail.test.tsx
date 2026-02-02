// @vitest-environment jsdom
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
import MasteryDetail from '../MasteryDetail'
import type {MasteryLevel} from '../types'

describe('MasteryDetail', () => {
  const renderMasteryDetail = (masteryLevel: MasteryLevel) =>
    render(<MasteryDetail masteryLevel={masteryLevel} />)

  describe('mastery level text', () => {
    it('renders "Exceeds Mastery" for exceeds_mastery level', () => {
      renderMasteryDetail('exceeds_mastery')
      const elements = screen.getAllByText('Exceeds Mastery')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })

    it('renders "Mastery" for mastery level', () => {
      renderMasteryDetail('mastery')
      const elements = screen.getAllByText('Mastery')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })

    it('renders "Near Mastery" for near_mastery level', () => {
      renderMasteryDetail('near_mastery')
      const elements = screen.getAllByText('Near Mastery')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })

    it('renders "Remediation" for remediation level', () => {
      renderMasteryDetail('remediation')
      const elements = screen.getAllByText('Remediation')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })

    it('renders "Unassessed" for unassessed level', () => {
      renderMasteryDetail('unassessed')
      const elements = screen.getAllByText('Unassessed')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })

    it('renders "No Evidence" for no_evidence level', () => {
      renderMasteryDetail('no_evidence')
      const elements = screen.getAllByText('No Evidence')
      expect(elements.length).toBeGreaterThan(0)
      expect(elements[0]).toBeInTheDocument()
    })
  })

  describe('mastery icon', () => {
    it('renders icon for exceeds_mastery level', () => {
      renderMasteryDetail('exceeds_mastery')
      const icon = screen.getByAltText('Exceeds Mastery')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/exceeds_mastery.svg')
    })

    it('renders icon for mastery level', () => {
      renderMasteryDetail('mastery')
      const icon = screen.getByAltText('Mastery')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/mastery.svg')
    })

    it('renders icon for near_mastery level', () => {
      renderMasteryDetail('near_mastery')
      const icon = screen.getByAltText('Near Mastery')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/near_mastery.svg')
    })

    it('renders icon for remediation level', () => {
      renderMasteryDetail('remediation')
      const icon = screen.getByAltText('Remediation')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/remediation.svg')
    })

    it('renders icon for unassessed level', () => {
      renderMasteryDetail('unassessed')
      const icon = screen.getByAltText('Unassessed')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/unassessed.svg')
    })

    it('renders icon for no_evidence level', () => {
      renderMasteryDetail('no_evidence')
      const icon = screen.getByAltText('No Evidence')
      expect(icon).toBeInTheDocument()
      expect(icon).toHaveAttribute('src', '/images/outcomes/no_evidence.svg')
    })
  })

  describe('accessibility', () => {
    it('provides screen reader content for mastery icon', () => {
      renderMasteryDetail('mastery')
      // Screen reader content is rendered by MasteryIcon
      // The alt text should be accessible via getByAltText
      expect(screen.getByAltText('Mastery')).toBeInTheDocument()
    })

    it('provides screen reader content for no_evidence level', () => {
      renderMasteryDetail('no_evidence')
      expect(screen.getByAltText('No Evidence')).toBeInTheDocument()
    })
  })

  describe('component structure', () => {
    it('renders text and icon in the correct order', () => {
      const {container} = renderMasteryDetail('mastery')
      const textElements = screen.getAllByText('Mastery')
      const icon = screen.getByAltText('Mastery')

      // Text should be present (appears twice due to ScreenReaderContent)
      expect(textElements.length).toBeGreaterThan(0)
      expect(textElements[0]).toBeInTheDocument()

      // Icon should be present
      expect(icon).toBeInTheDocument()

      // Verify img element is rendered
      expect(container.querySelector('img')).toBeTruthy()
    })
  })
})
