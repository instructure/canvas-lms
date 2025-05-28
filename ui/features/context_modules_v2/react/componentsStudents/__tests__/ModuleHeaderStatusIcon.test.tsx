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
import ModuleHeaderStatusIcon from '../ModuleHeaderStatusIcon'
import {ModuleProgression, ModuleRequirement} from '../../utils/types'

interface ModuleProgressionOverrides {
  workflowState?: string
  requirementsMet?: ModuleRequirement[]
  completed?: boolean
  locked?: boolean
  unlocked?: boolean
  started?: boolean
  requirementCount?: number
}

const buildDefaultProps = (overrides: ModuleProgressionOverrides = {}) => {
  const requirementCount = overrides.requirementCount ?? 2

  const defaultRequirementsMet: ModuleRequirement[] = Array.from(
    {length: requirementCount},
    (_, index) => ({
      id: `req-${index + 1}`,
      type: 'assignment',
      minScore: 100,
      minPercentage: 100,
    }),
  )

  const progression: ModuleProgression = {
    id: 'module-1',
    _id: 'module-1',
    workflowState: 'completed',
    requirementsMet: overrides.requirementsMet ?? defaultRequirementsMet,
    completed: overrides.completed ?? true,
    locked: overrides.locked ?? false,
    unlocked: overrides.unlocked ?? true,
    started: overrides.started ?? true,
  }

  return progression
}

const setUp = (overrides: ModuleProgressionOverrides = {}) => {
  const progression = buildDefaultProps(overrides)
  return render(<ModuleHeaderStatusIcon progression={progression} />)
}

describe('ModuleHeaderStatusIcon', () => {
  it('should render the success icon', () => {
    const container = setUp()
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-header-status-icon-success')).toBeInTheDocument()
  })

  it('should render the lock icon when completely locked', () => {
    const container = setUp({
      completed: false,
      locked: true,
      unlocked: false,
      started: false,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-header-status-icon-lock')).toBeInTheDocument()
  })

  it('should render the lock icon when started and locked are both true', () => {
    const container = setUp({
      completed: false,
      locked: true,
      unlocked: false,
      started: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-header-status-icon-lock')).toBeInTheDocument()
  })

  it('should render the lock icon when completed and locked are both true', () => {
    const container = setUp({
      completed: true,
      locked: true,
      unlocked: false,
      started: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-header-status-icon-lock')).toBeInTheDocument()
  })

  it('should render the empty icon', () => {
    const container = setUp({
      workflowState: 'unlocked',
      requirementsMet: [
        {id: '1', type: 'assignment', minScore: 100, minPercentage: 100},
        {id: '2', type: 'assignment', minScore: 100, minPercentage: 100},
      ],
      completed: false,
      locked: false,
      unlocked: true,
      started: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('module-header-status-icon-empty')).toBeInTheDocument()
  })
})
