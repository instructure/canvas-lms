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
import ModuleProgressionStatusBar from '../ModuleProgressionStatusBar'
import {CompletionRequirement, ModuleProgression} from '../../utils/types'

interface TestPropsOverrides {
  completionRequirements?: Partial<CompletionRequirement>[] | []
  progression?: Partial<ModuleProgression>
  // For controlling the number of requirements
  requirementCount?: number
  // For controlling how many requirements are met
  metRequirementsCount?: number
}

const buildDefaultProps = (overrides: TestPropsOverrides = {}) => {
  const requirementCount = overrides.requirementCount ?? 2
  const metRequirementsCount = overrides.metRequirementsCount ?? requirementCount

  // Create default requirements
  const defaultRequirements: CompletionRequirement[] = Array.from(
    {length: requirementCount},
    (_, index) => ({
      id: `req-${index + 1}`,
      type: 'assignment',
      minScore: 100,
      minPercentage: 100,
      completed: index < metRequirementsCount, // Mark as completed if index < metRequirementsCount
    }),
  )

  // Apply any requirement overrides if provided
  const completionRequirements =
    overrides.completionRequirements === undefined
      ? defaultRequirements
      : overrides.completionRequirements.length === 0
        ? []
        : defaultRequirements.map((req, index) => ({
            ...req,
            ...(overrides.completionRequirements?.[index] || {}),
          }))

  // Create requirements met array based on metRequirementsCount
  const requirementsMet = completionRequirements.filter((_, index) => index < metRequirementsCount)

  // Create default progression
  const defaultProgression: ModuleProgression = {
    id: 'module-1',
    _id: 'module-1',
    workflowState: metRequirementsCount >= requirementCount ? 'completed' : 'started',
    requirementsMet,
    completed: metRequirementsCount >= requirementCount,
    locked: false,
    unlocked: true,
    started: true,
    ...overrides.progression,
  }

  return {
    completionRequirements,
    progression: defaultProgression,
  }
}

const setUp = (props: TestPropsOverrides = {}) => {
  const {completionRequirements, progression} = buildDefaultProps(props)
  return render(
    <ModuleProgressionStatusBar
      completionRequirements={completionRequirements}
      progression={progression}
    />,
  )
}

describe('ModuleProgressionStatusBar', () => {
  it('when completionRequirements is empty', () => {
    const container = setUp({
      completionRequirements: [],
    })
    expect(container.container).toBeInTheDocument()
    expect(container.queryByText('0/0 Required Items Completed')).not.toBeInTheDocument()
  })

  it('should render the correct completion percentage 100%', () => {
    // All requirements are met by default
    const container = setUp()
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('2/2 Required Items Completed')).toBeInTheDocument()
  })

  it('should render the correct completion percentage 50%', () => {
    const container = setUp({
      metRequirementsCount: 1, // Only 1 of 2 requirements met
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('1/2 Required Items Completed')).toBeInTheDocument()
  })

  it('should render the correct completion percentage 0%', () => {
    const container = setUp({
      metRequirementsCount: 0, // No requirements met
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('0/2 Required Items Completed')).toBeInTheDocument()
  })

  it('should handle custom requirement counts', () => {
    const container = setUp({
      requirementCount: 4,
      metRequirementsCount: 2,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('2/4 Required Items Completed')).toBeInTheDocument()
  })

  it('should render progress bar with a x/1 when requirementCount is 1', () => {
    const container = setUp({
      requirementCount: 1,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('1/1 Required Items Completed')).toBeInTheDocument()
  })
})
