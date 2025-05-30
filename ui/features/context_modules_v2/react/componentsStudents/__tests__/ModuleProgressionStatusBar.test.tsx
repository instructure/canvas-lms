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
  completionRequirements?: CompletionRequirement[] | []
  progression?: Partial<ModuleProgression>
  requirementCount?: number
}

const buildDefaultProps = (overrides: TestPropsOverrides = {}) => {
  const defaultCompletionRequirements: CompletionRequirement[] = []

  const defaultProgression: ModuleProgression = {
    id: 'module-1',
    _id: 'module-1',
    workflowState: 'completed',
    requirementsMet: [],
    completed: true,
    locked: false,
    unlocked: true,
    started: true,
  }

  return {
    completionRequirements: Array.isArray(overrides.completionRequirements)
      ? overrides.completionRequirements
      : defaultCompletionRequirements,
    progression: overrides.progression
      ? {
          ...defaultProgression,
          ...overrides.progression,
        }
      : defaultProgression,
    requirementCount: overrides.requirementCount || undefined,
  }
}

const setUp = (props: TestPropsOverrides = {}) => {
  const {completionRequirements, progression, requirementCount} = buildDefaultProps(props)
  return render(
    <ModuleProgressionStatusBar
      completionRequirements={completionRequirements}
      progression={progression}
      requirementCount={requirementCount}
    />,
  )
}

const baseReqs = [
  {
    id: '1',
    type: 'must_view',
    minScore: undefined,
    minPercentage: undefined,
  },
  {
    id: '2',
    type: 'must_view',
    minScore: undefined,
    minPercentage: undefined,
  },
  {
    id: '3',
    type: 'must_view',
    minScore: undefined,
    minPercentage: undefined,
  },
  {
    id: '4',
    type: 'must_view',
    minScore: undefined,
    minPercentage: undefined,
  },
]

describe('ModuleProgressionStatusBar', () => {
  it('when completionRequirements is empty', () => {
    const container = setUp({
      completionRequirements: [],
    })
    expect(container.container).toBeInTheDocument()
    expect(container.queryByText('0 of 0 Required Items')).not.toBeInTheDocument()
  })

  it('should render the correct completion percentage 100%', () => {
    // All requirements are met by default
    const container = setUp({
      completionRequirements: [
        {
          id: '1',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
        {
          id: '2',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
      ],
      progression: {
        requirementsMet: [
          {
            id: '1',
            type: 'must_view',
            minScore: undefined,
            minPercentage: undefined,
          },
          {
            id: '2',
            type: 'must_view',
            minScore: undefined,
            minPercentage: undefined,
          },
        ],
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('2 of 2 Required Items')).toBeInTheDocument()
  })

  it('should render the correct completion percentage 50%', () => {
    const container = setUp({
      completionRequirements: [
        {
          id: '1',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
        {
          id: '2',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
      ],
      progression: {
        requirementsMet: [
          {
            id: '1',
            type: 'must_view',
            minScore: undefined,
            minPercentage: undefined,
          },
        ],
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('1 of 2 Required Items')).toBeInTheDocument()
  })

  it('should render the correct completion percentage 0%', () => {
    const container = setUp({
      progression: {
        requirementsMet: [],
      },
      completionRequirements: [
        {
          id: '1',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
        {
          id: '2',
          type: 'must_view',
          minScore: undefined,
          minPercentage: undefined,
        },
      ],
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('0 of 2 Required Items')).toBeInTheDocument()
  })

  it('should handle custom requirement counts', () => {
    const container = setUp({
      completionRequirements: baseReqs,
      progression: {
        requirementsMet: baseReqs.slice(0, 2),
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('2 of 4 Required Items')).toBeInTheDocument()
  })

  it('should render progress bar with a x/1 when requirementCount is 1', () => {
    const container = setUp({
      completionRequirements: baseReqs,
      requirementCount: 1,
      progression: {
        requirementsMet: baseReqs.slice(0, 1),
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('1 of 1 Required Items')).toBeInTheDocument()
  })

  it('should render the correct completion percentage 50% when a requirement is met but does not match a completion requirement', () => {
    const container = setUp({
      completionRequirements: [
        {
          id: '1',
          type: 'must_view',
        },
        {
          id: '2',
          type: 'must_view',
        },
      ],
      progression: {
        requirementsMet: [
          {
            id: '1',
            type: 'must_view',
          },
          {
            id: '2',
            type: 'must_mark_done',
          },
        ],
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('1 of 2 Required Items')).toBeInTheDocument()
  })
})
