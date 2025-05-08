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
import ModuleItemStatusIcon from '../ModuleItemStatusIcon'
import {CompletionRequirement, ModuleItemContent, ModuleRequirement} from '../../utils/types'

interface TestPropsOverrides {
  itemId?: string
  completionRequirement?: Partial<CompletionRequirement>
  requirementsMet?: ModuleRequirement[]
  content?: Partial<ModuleItemContent>
  // For controlling the due date
  dueDateOffsetHours?: number // Positive for future, negative for past
  isCompleted?: boolean
}

const buildDefaultProps = (overrides: TestPropsOverrides = {}) => {
  const itemId = overrides.itemId ?? 'item-1'

  // Create default completion requirement
  const defaultCompletionRequirement: CompletionRequirement = {
    id: itemId,
    type: 'assignment',
    minScore: 100,
    minPercentage: 100,
    ...overrides.completionRequirement,
  }

  // Set up due date
  const dueDateOffsetHours = overrides.dueDateOffsetHours ?? 72 // 3 days in the future by default
  const dueDate = new Date(Date.now() + dueDateOffsetHours * 60 * 60 * 1000)

  // Create default content
  const defaultContent: ModuleItemContent = {
    _id: itemId,
    title: 'Test Item',
    submissionsConnection: {
      nodes: [
        {
          _id: `submission-${itemId}`,
          cachedDueDate: dueDate.toISOString(),
        },
      ],
    },
    ...overrides.content,
  }

  // Create requirements met array depending on isCompleted
  const isCompleted = overrides.isCompleted ?? false
  const defaultRequirementsMet: ModuleRequirement[] = isCompleted
    ? [
        {
          id: itemId,
          type: 'assignment',
          min_score: 100,
          min_percentage: 100,
        },
      ]
    : []

  return {
    itemId,
    completionRequirement: defaultCompletionRequirement,
    requirementsMet: overrides.requirementsMet ?? defaultRequirementsMet,
    content: defaultContent,
  }
}

const setUp = (overrides: TestPropsOverrides = {}) => {
  const {itemId, completionRequirement, requirementsMet, content} = buildDefaultProps(overrides)
  return render(
    <ModuleItemStatusIcon
      itemId={itemId}
      completionRequirement={completionRequirement}
      requirementsMet={requirementsMet}
      content={content}
    />,
  )
}

describe('ModuleItemStatusIcon', () => {
  it('should render "Complete"', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: true,
      dueDateOffsetHours: 72, // Due in the future
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Complete')).toBeInTheDocument()
  })

  it('should render "Overdue"', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      dueDateOffsetHours: -72, // Due in the past (72 hours ago)
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Overdue')).toBeInTheDocument()
  })

  it('should render "Assigned"', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      dueDateOffsetHours: 72, // Due in the future
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Assigned')).toBeInTheDocument()
  })

  it('should render nothing when requirements are not met', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      content: {
        submissionsConnection: {
          nodes: [],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })
})
