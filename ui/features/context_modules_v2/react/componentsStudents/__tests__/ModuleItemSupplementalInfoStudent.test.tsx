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
    title: 'Test Item',
    pointsPossible: 100,
    submissionsConnection: {
      nodes: [
        {
          _id: '1',
          cachedDueDate: testDate.toISOString(),
        },
      ],
    },
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
) => {
  return render(
    <ModuleItemSupplementalInfoStudent
      completionRequirement={completionRequirement}
      content={content}
      itemIcon={itemIcon}
      itemTypeText={itemTypeText}
    />,
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
    expect(container.getByText('Submit')).toBeInTheDocument()
  })

  it('should render null when nothing is provided', () => {
    const {container} = render(
      <ModuleItemSupplementalInfoStudent
        content={null as any}
        completionRequirement={null as any}
      />,
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
      expect(container.getByText('Score at least 100.0')).toBeInTheDocument()
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
      expect(container.getByText('Submit')).toBeInTheDocument()
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
      expect(container.getByText('Mark done')).toBeInTheDocument()
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
})
