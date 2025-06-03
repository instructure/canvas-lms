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
  moduleCompleted?: boolean
  completionRequirement?: Partial<CompletionRequirement>
  requirementsMet?: ModuleRequirement[]
  content?: Partial<ModuleItemContent>
  dueDateOffsetHours?: number
  isCompleted?: boolean
}

const buildDefaultProps = (overrides: TestPropsOverrides = {}) => {
  const itemId = overrides.itemId ?? 'item-1'

  // Create default completion requirement if not explicitly undefined
  let defaultCompletionRequirement = undefined
  if (!('completionRequirement' in overrides && overrides.completionRequirement === undefined)) {
    defaultCompletionRequirement = {
      id: itemId,
      type: 'min_score',
      minScore: 100,
      minPercentage: 100,
    }
  }

  // Set up due date
  const dueDateOffsetHours = overrides.dueDateOffsetHours ?? 72
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
          missing: overrides.dueDateOffsetHours && overrides.dueDateOffsetHours < 0 ? true : false,
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
          type: 'min_score',
          minScore: 100,
          minPercentage: 100,
        },
      ]
    : []

  return {
    itemId,
    moduleCompleted: overrides?.moduleCompleted ?? false,
    completionRequirements: defaultCompletionRequirement ? [defaultCompletionRequirement] : [],
    requirementsMet: overrides.requirementsMet ?? defaultRequirementsMet,
    content: defaultContent,
  }
}

const setUp = (overrides: TestPropsOverrides = {}) => {
  const {itemId, moduleCompleted, completionRequirements, requirementsMet, content} =
    buildDefaultProps(overrides)
  return render(
    <ModuleItemStatusIcon
      itemId={itemId}
      moduleCompleted={moduleCompleted}
      completionRequirements={completionRequirements}
      requirementsMet={requirementsMet}
      content={content}
    />,
  )
}

describe('ModuleItemStatusIcon', () => {
  it('should render "Complete" when requirements are met and completionRequirement exists', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: true,
      dueDateOffsetHours: 72,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Complete')).toBeInTheDocument()
  })

  it('should render "Missing" when submission is marked as missing', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      content: {
        submissionsConnection: {
          nodes: [
            {
              _id: 'submission-1',
              missing: true,
            },
          ],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Missing')).toBeInTheDocument()
  })

  it('should render assigned icon when completionRequirement exists but not completed', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      dueDateOffsetHours: 72,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('assigned-icon')).toBeInTheDocument()
  })

  it('should not render assigned icon when module is completed', () => {
    const container = setUp({
      itemId: '1',
      moduleCompleted: true,
      dueDateOffsetHours: 72,
    })
    expect(container.container).toBeInTheDocument()
    expect(container.queryByTestId('assigned-icon')).toBeNull()
  })

  it('should prioritize "Missing" over "Complete" status', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: true,
      content: {
        submissionsConnection: {
          nodes: [
            {
              _id: 'submission-1',
              missing: true,
            },
          ],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Missing')).toBeInTheDocument()
    expect(container.queryByText('Complete')).not.toBeInTheDocument()
  })

  it('should not render "Missing" when module is completed', () => {
    const container = setUp({
      itemId: '1',
      moduleCompleted: true,
      isCompleted: false,
      content: {
        submissionsConnection: {
          nodes: [
            {
              _id: 'submission-1',
              missing: true,
            },
          ],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.queryByText('Missing')).not.toBeInTheDocument()
  })

  it('should render nothing when no completionRequirement and submissions array is empty', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      completionRequirement: undefined,
      content: {
        submissionsConnection: {
          nodes: [],
        },
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })

  it('should render nothing when both completionRequirement and submissions are undefined', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      completionRequirement: undefined,
      content: {
        submissionsConnection: undefined,
      },
    })
    expect(container.container).toBeInTheDocument()
    expect(container.container).toBeEmptyDOMElement()
  })

  it('should render assigned icon when a requirement is met but does not match a completion requirement', () => {
    const container = setUp({
      itemId: '1',
      isCompleted: false,
      completionRequirement: {
        id: '1',
        type: 'must_view',
      },
      requirementsMet: [
        {
          id: '1',
          type: 'must_mark_done',
        },
      ],
    })
    expect(container.container).toBeInTheDocument()
    expect(container.getByTestId('assigned-icon')).toBeInTheDocument()
  })

  describe('In progress Module Items show Tooltips', () => {
    const completionRequirementList = [
      {
        id: '1',
        type: 'min_score',
        toolTipMessage: 'Must score at least a 100',
      },
      {
        id: '2',
        type: 'must_view',
        toolTipMessage: 'Must view the page',
      },
      {
        id: '3',
        type: 'must_mark_done',
        toolTipMessage: 'Must mark as done',
      },
      {
        id: '4',
        type: 'must_submit',
        toolTipMessage: 'Must submit the assignment',
      },
      {
        id: '5',
        type: 'must_contribute',
        toolTipMessage: 'Must contribute to the page',
      },
      {
        id: '6',
        type: 'min_percentage',
        toolTipMessage: 'Must score at least a 100%',
      },
      {
        id: '7',
        type: 'any_other_type',
        toolTipMessage: 'Not yet completed',
      },
    ]

    completionRequirementList.forEach(({id, type, toolTipMessage}) => {
      it(`should render tooltip "${toolTipMessage}" for in progress item with type "${type}"`, () => {
        const container = setUp({
          itemId: id,
          isCompleted: false,
          completionRequirement: {
            id,
            type,
          },
        })
        expect(container.getByTestId('assigned-icon')).toBeInTheDocument()
        const tooltipList = container.getAllByRole('tooltip')
        expect(tooltipList).toHaveLength(1)
        expect(tooltipList[0]).toBeInTheDocument()
      })
    })
  })
})
