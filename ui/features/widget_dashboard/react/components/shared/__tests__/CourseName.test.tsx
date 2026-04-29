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
import {CourseName} from '../CourseName'

// Mock TruncateText to simulate truncation behavior in tests
vi.mock('@instructure/ui-truncate-text', () => ({
  TruncateText: ({
    children,
    onUpdate,
    maxLines,
  }: {
    children: string
    onUpdate?: (truncated: boolean) => void
    maxLines?: number
  }) => {
    React.useEffect(() => {
      if (onUpdate && children && children.length > 100) {
        onUpdate(true)
      }
    }, [children, onUpdate])

    const displayText =
      children && children.length > 100 ? `${children.substring(0, 70)}...` : children

    return displayText
  },
}))

describe('CourseName', () => {
  describe('Component rendering', () => {
    it('should render with tooltip for long course name', async () => {
      const longName =
        'This is a Very Long Course Name That Should Be Truncated Because It Exceeds The Maximum Number of Characters Allowed for Two Lines'
      const truncatedName =
        'This is a Very Long Course Name That Should Be Truncated Because It Ex...'

      const user = userEvent.setup()

      render(<CourseName courseName={longName} />)

      // Verify truncated text is displayed
      expect(screen.getByText(truncatedName)).toBeInTheDocument()

      // The tooltip wrapper should be focusable and have tabIndex 0
      const truncatedTextElement = screen.getByText(truncatedName)
      const tooltipWrapper = truncatedTextElement.closest('[tabindex="0"]')
      expect(tooltipWrapper).toBeInTheDocument()
      expect(tooltipWrapper).toHaveAttribute('tabIndex', '0')

      // Hover over the tooltip wrapper to trigger the tooltip
      if (tooltipWrapper) {
        await user.hover(tooltipWrapper)
      }

      // After hovering, the full name should appear in the tooltip
      // We need to find the tooltip specifically (not the ScreenReaderContent)
      const elementList = await screen.findAllByText(longName)

      // The tooltip will be inside an element with an id starting with 'Tooltip___'
      const tooltip = elementList.find(element => {
        const tooltipContainer = element.closest('[id^="Tooltip___"]')
        return tooltipContainer !== null
      })
      expect(tooltip).toBeInTheDocument()
    })

    it('should not render with tooltip for normal course name length', () => {
      const shortName = 'Introduction to Programming'
      render(<CourseName courseName={shortName} />)

      expect(screen.getByText(shortName)).toBeInTheDocument()

      // Check that there's no focusable wrapper (should not find element with tabindex="0")
      const textElement = screen.getByText(shortName)
      const tooltipWrapper = textElement.closest('[tabindex="0"]')
      expect(tooltipWrapper).not.toBeInTheDocument()
    })
  })
})
