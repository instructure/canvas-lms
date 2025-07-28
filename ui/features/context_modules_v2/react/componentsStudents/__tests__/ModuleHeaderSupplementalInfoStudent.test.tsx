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
import {render} from '@testing-library/react'
import {ModuleHeaderSupplementalInfoStudent} from '../ModuleHeaderSupplementalInfoStudent'
import {CompletionRequirement, ModuleStatistics} from '../../utils/types'

type Props = {
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  submissionStatistics?: ModuleStatistics
  moduleCompleted?: boolean
}

const buildDefaultProps = (overrides: Partial<Props> = {}) => {
  return {
    submissionStatistics: overrides.submissionStatistics || {
      latestDueAt: null,
      missingAssignmentCount: 0,
    },
  }
}

const setUp = (props = buildDefaultProps()) => {
  return render(
    <ModuleHeaderSupplementalInfoStudent submissionStatistics={props.submissionStatistics} />,
  )
}

describe('ModuleHeaderSupplementalInfoStudent', () => {
  it('renders date with consistent format across screen sizes', () => {
    const testDate = new Date(Date.now() + 72 * 60 * 60 * 1000)
    const container = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: testDate.toISOString(),
          missingAssignmentCount: 0,
        },
      }),
    )
    expect(container.container).toBeInTheDocument()

    // Desktop version should show formatted date
    expect(
      container.getByText(/Due: \w+ \d+,?/, {selector: '.visible-desktop'}),
    ).toBeInTheDocument()

    // Mobile version should now also show formatted date (not numeric) due to alwaysUseSpecifiedFormat
    expect(container.getByText(/Due: \w+ \d+,?/, {selector: '.hidden-desktop'})).toBeInTheDocument()

    // Should have FriendlyDatetime component with time element
    const timeElement = container.container.querySelector('time')
    expect(timeElement).toBeInTheDocument()
  })

  it('does not render when no due date provided', () => {
    const container = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: null,
          missingAssignmentCount: 0,
        },
      }),
    )
    expect(container.container).toBeInTheDocument()
    expect(container.container.querySelector('time')).not.toBeInTheDocument()
  })

  it('uses alwaysUseSpecifiedFormat to maintain consistent date format', () => {
    // Use a specific date to ensure consistent test results
    const testDate = new Date('2025-01-15T10:00:00.000Z')
    const container = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: testDate.toISOString(),
          missingAssignmentCount: 0,
        },
      }),
    )

    // Get the desktop and mobile text content
    const desktopElement = container.container.querySelector('.visible-desktop')
    const mobileElement = container.container.querySelector('.hidden-desktop')

    expect(desktopElement).toBeInTheDocument()
    expect(mobileElement).toBeInTheDocument()

    // Both should show the same formatted text (not numeric on mobile)
    const desktopText = desktopElement?.textContent
    const mobileText = mobileElement?.textContent

    expect(desktopText).toMatch(/Due: \w+ \d+/)
    expect(mobileText).toMatch(/Due: \w+ \d+/)
    expect(desktopText).toBe(mobileText) // Should be exactly the same

    // Should NOT contain numeric date format like "1/15/2025"
    expect(mobileText).not.toMatch(/\d+\/\d+\/\d+/)
  })
})
