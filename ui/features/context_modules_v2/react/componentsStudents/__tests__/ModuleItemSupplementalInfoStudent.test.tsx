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
import ModuleItemSupplementalInfoStudent from '../ModuleItemSupplementalInfoStudent'
import {CompletionRequirement, ModuleItemContent} from '../../utils/types'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'

type DefaultPropsOverrides = {
  completionRequirement?: Partial<CompletionRequirement>
  content?: Partial<ModuleItemContent>
  testDate?: Date
}

const buildDefaultProps = (overrides: DefaultPropsOverrides = {}) => {
  const testDate = overrides.testDate || new Date(Date.now())

  const defaultCompletionRequirement: CompletionRequirement = {
    id: '1',
    type: 'must_submit',
    minScore: 100,
    minPercentage: 100,
    ...overrides.completionRequirement,
  }

  const defaultContent: ModuleItemContent = {
    _id: '1',
    pointsPossible: 100,
    submissionsConnection: {
      nodes: [
        {
          _id: '1',
          cachedDueDate: testDate.toISOString(),
        },
      ],
    },
    type: 'Assignment',
    ...overrides.content,
  }

  return {
    completionRequirement: defaultCompletionRequirement,
    content: defaultContent,
    testDate,
  }
}

const setUp = (
  completionRequirement: CompletionRequirement,
  content: ModuleItemContent,
  itemIcon?: React.ReactNode,
  itemTypeText?: string,
  restrictQuantitativeData?: boolean,
) => {
  return render(
    <ContextModuleProvider
      {...contextModuleDefaultProps}
      restrictQuantitativeData={restrictQuantitativeData ?? false}
    >
      <ModuleItemSupplementalInfoStudent
        completionRequirement={completionRequirement}
        content={content}
        itemIcon={itemIcon}
        itemTypeText={itemTypeText}
      />
    </ContextModuleProvider>,
  )
}

describe('ModuleItemSupplementalInfoStudent', () => {
  it('should render due date', () => {
    const testDate = new Date(Date.now() - 72 * 60 * 60 * 1000)
    const props = buildDefaultProps({testDate})
    const container = setUp(props.completionRequirement, props.content)
    expect(container.container).toBeInTheDocument()
    // Check for the due date using data-testid instead of specific date format
    expect(container.getByTestId('due-date')).toBeInTheDocument()
    expect(container.getByText('100 pts')).toBeInTheDocument()
    expect(container.getByText('Submit assignment')).toBeInTheDocument()
  })

  it('should render null when nothing is provided', () => {
    const {container} = render(
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <ModuleItemSupplementalInfoStudent
          content={null as any}
          completionRequirement={null as any}
        />
      </ContextModuleProvider>,
    )
    expect(container).toBeEmptyDOMElement()
  })

  describe('completion requirements', () => {
    it('should render completion requirement for min_score', () => {
      const testDate = new Date(Date.now() + 72 * 60 * 60 * 1000)
      const props = buildDefaultProps({
        completionRequirement: {type: 'min_score'},
        content: {
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)
      expect(container.container).toBeInTheDocument()
      expect(container.queryByText(testDate.toLocaleDateString())).not.toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
      expect(container.getByText('Score at least 100.0 points')).toBeInTheDocument()
    })

    it('should render completion requirement for min_percentage', () => {
      const props = buildDefaultProps({
        completionRequirement: {type: 'min_percentage'},
        content: {
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
      expect(container.getByText('Score at least 100%')).toBeInTheDocument()
    })

    it('should render completion requirement for must_contribute', () => {
      const props = buildDefaultProps({
        completionRequirement: {type: 'must_contribute'},
        content: {
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
      expect(container.getByText('Contribute')).toBeInTheDocument()
    })

    it('should render completion requirement for must_submit', () => {
      const props = buildDefaultProps({
        content: {
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
      expect(container.getByText('Submit assignment')).toBeInTheDocument()
    })

    it('should render completion requirement for must_mark_done', () => {
      const props = buildDefaultProps({
        completionRequirement: {type: 'must_mark_done'},
        content: {
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
      expect(container.getByText('Mark as done')).toBeInTheDocument()
    })
  })

  describe('icon and item type display', () => {
    it('renders itemIcon and itemTypeText when provided', () => {
      const props = buildDefaultProps({})
      const itemIcon = <div data-testid="item-icon">Icon</div>
      const itemTypeText = 'discussion'

      const container = setUp(props.completionRequirement, props.content, itemIcon, itemTypeText)

      expect(container.getByTestId('item-icon')).toBeInTheDocument()
      expect(container.getByText('discussion')).toBeInTheDocument()
    })

    it('does not render itemIcon or itemTypeText when not provided', () => {
      const props = buildDefaultProps({})
      const container = setUp(props.completionRequirement, props.content)

      // Both should not be present since we're not rendering them
      expect(container.queryByTestId('item-icon')).not.toBeInTheDocument()
      expect(container.queryByText('discussion')).not.toBeInTheDocument()
    })
  })

  describe('restrict quantitative data', () => {
    it('should show points when restrictQuantitativeData is false', () => {
      const props = buildDefaultProps({})
      const container = setUp(
        props.completionRequirement,
        props.content,
        undefined,
        undefined,
        false,
      )

      expect(container.getByText('100 pts')).toBeInTheDocument()
    })

    it('should hide points when restrictQuantitativeData is true', () => {
      const props = buildDefaultProps({})
      const container = setUp(
        props.completionRequirement,
        props.content,
        undefined,
        undefined,
        true,
      )

      expect(container.queryByText('100 pts')).not.toBeInTheDocument()
    })

    it('should show points when restrictQuantitativeData is undefined (defaults to false)', () => {
      const props = buildDefaultProps({})
      const container = setUp(props.completionRequirement, props.content)

      expect(container.getByText('100 pts')).toBeInTheDocument()
    })

    it('should still show due date when restrictQuantitativeData is true', () => {
      const props = buildDefaultProps({})
      const container = setUp(
        props.completionRequirement,
        props.content,
        undefined,
        undefined,
        true,
      )

      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.queryByText('100 pts')).not.toBeInTheDocument()
    })

    it('should still show completion requirements when restrictQuantitativeData is true', () => {
      const props = buildDefaultProps({})
      const container = setUp(
        props.completionRequirement,
        props.content,
        undefined,
        undefined,
        true,
      )

      expect(container.getByText('Submit assignment')).toBeInTheDocument()
      expect(container.queryByText('100 pts')).not.toBeInTheDocument()
    })
  })

  describe('ungraded discussion todo dates', () => {
    const testDate = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString()

    it('should render todo date for ungraded discussion with todoDate', () => {
      const props = buildDefaultProps({
        content: {
          type: 'Discussion',
          graded: false,
          todoDate: testDate,
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)

      expect(container.getByTestId('todo-date')).toBeInTheDocument()
      // Verify that the component contains the todo date text somewhere
      expect(container.container.innerHTML).toContain('Due: ')
    })

    it('should render due date for graded discussion with cachedDueDate', () => {
      const props = buildDefaultProps({
        content: {
          type: 'Discussion',
          graded: true,
          todoDate: testDate,
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: testDate}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)

      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.container.innerHTML).toContain('Due: ')
    })

    it('should not render todo date for graded discussion even with todoDate', () => {
      const props = buildDefaultProps({
        content: {
          type: 'Discussion',
          graded: true,
          todoDate: testDate,
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)

      expect(container.queryByText(/Due:/)).not.toBeInTheDocument()
    })

    it('should not render todo date for ungraded discussion without todoDate', () => {
      const props = buildDefaultProps({
        content: {
          type: 'Discussion',
          graded: false,
          todoDate: undefined,
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)

      expect(container.queryByTestId('due-date')).not.toBeInTheDocument()
      expect(container.queryByTestId('todo-date')).not.toBeInTheDocument()
    })

    it('should not render todo date for non-discussion items', () => {
      const props = buildDefaultProps({
        content: {
          type: 'Assignment',
          graded: false,
          todoDate: testDate,
          submissionsConnection: {
            nodes: [{_id: '1', cachedDueDate: undefined}],
          },
        },
      })
      const container = setUp(props.completionRequirement, props.content)

      expect(container.queryByText(/Due:/)).not.toBeInTheDocument()
    })
  })
})
