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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {CompletionRequirement, ModuleProgression} from '../../utils/types'

const queryClient = new QueryClient()

const setUp = (
  moduleId: string,
  completionRequirements?: CompletionRequirement[],
  requirementCount?: number,
  progression?: ModuleProgression,
) => {
  return render(
    <QueryClientProvider client={queryClient}>
      <ModuleHeaderSupplementalInfoStudent
        moduleId={moduleId}
        completionRequirements={completionRequirements}
        requirementCount={requirementCount}
        progression={progression}
      />
    </QueryClientProvider>,
  )
}

describe('ModuleHeaderSupplementalInfoStudent', () => {
  it('renders date, overdue count, and requirement', () => {
    const testDate = new Date(Date.now() - 72 * 60 * 60 * 1000)
    queryClient.setQueryData(['moduleItemsStudent', '1'], {
      moduleItems: [
        {
          _id: '1',
          content: {
            submissionsConnection: {
              nodes: [
                {
                  cachedDueDate: testDate.toISOString(),
                },
              ],
            },
          },
        },
      ],
    })
    const container = setUp(
      '1',
      [
        {
          id: '1',
          type: 'assignment',
          minScore: 100,
          minPercentage: 100,
        },
      ],
      0,
      {
        id: '1',
        _id: '1',
        workflowState: 'started',
        requirementsMet: [],
        completed: false,
        locked: false,
        unlocked: true,
        started: true,
      },
    )
    expect(container.container).toBeInTheDocument()
    expect(container.getByText(`Due: ${testDate.toDateString()}`)).toBeInTheDocument()
    expect(container.getByText('1 Overdue Assignment')).toBeInTheDocument()
    expect(container.getByText('Requirement: Complete All Items')).toBeInTheDocument()
    expect(container.getAllByText('|')).toHaveLength(2)
  })

  it('renders date', () => {
    const testDate = new Date(Date.now() + 72 * 60 * 60 * 1000)
    queryClient.setQueryData(['moduleItemsStudent', '1'], {
      moduleItems: [
        {
          _id: '1',
          content: {
            submissionsConnection: {
              nodes: [
                {
                  cachedDueDate: testDate.toISOString(),
                },
              ],
            },
          },
        },
      ],
    })
    const container = setUp('1', [], 0, {
      id: '1',
      _id: '1',
      workflowState: 'started',
      requirementsMet: [],
      completed: false,
      locked: false,
      unlocked: true,
      started: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText(`Due: ${testDate.toDateString()}`)).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  it('renders requirement', () => {
    queryClient.setQueryData(['moduleItemsStudent', '1'], {
      moduleItems: [
        {
          _id: '1',
          content: {
            submissionsConnection: {
              nodes: [
                {
                  cachedDueDate: null,
                },
              ],
            },
          },
        },
      ],
    })
    const container = setUp(
      '1',
      [
        {
          id: '1',
          type: 'assignment',
          minScore: 100,
          minPercentage: 100,
        },
      ],
      1,
      {
        id: '1',
        _id: '1',
        workflowState: 'started',
        requirementsMet: [],
        completed: false,
        locked: false,
        unlocked: true,
        started: true,
      },
    )
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Requirement: Complete One Item')).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  it('renders due date and overdue count', () => {
    const testDate = new Date(Date.now() - 72 * 60 * 60 * 1000)
    queryClient.setQueryData(['moduleItemsStudent', '1'], {
      moduleItems: [
        {
          _id: '1',
          content: {
            submissionsConnection: {
              nodes: [
                {
                  cachedDueDate: testDate.toISOString(),
                },
              ],
            },
          },
        },
      ],
    })
    const container = setUp('1', [], 0, {
      id: '1',
      _id: '1',
      workflowState: 'started',
      requirementsMet: [],
      completed: false,
      locked: false,
      unlocked: true,
      started: true,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText(`Due: ${testDate.toDateString()}`)).toBeInTheDocument()
    expect(container.getByText('1 Overdue Assignment')).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(1)
  })
})
