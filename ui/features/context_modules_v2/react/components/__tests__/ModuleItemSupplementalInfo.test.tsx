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
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleItemSupplementalInfo from '../ModuleItemSupplementalInfo'
import type {ModuleItemContent, CompletionRequirement, Checkpoint} from '../../utils/types'

const defaultCompletionRequirement: CompletionRequirement = {
  id: '19',
  type: 'must_view',
  completed: false,
}

const currentDate = new Date().toISOString()
const defaultContent: ModuleItemContent = {
  id: '19',
  title: 'Test Module Item',
  dueAt: currentDate,
  pointsPossible: 100,
}

const checkpointDate1 = new Date('2024-01-20T23:59:00Z').toISOString()
const checkpointDate2 = new Date('2024-01-22T23:59:00Z').toISOString()

const defaultCheckpoints: Checkpoint[] = [
  {
    dueAt: checkpointDate1,
    name: 'Reply to Topic',
    tag: 'reply_to_topic',
  },
  {
    dueAt: checkpointDate2,
    name: 'Required Replies',
    tag: 'reply_to_entry',
  },
]

const discussionContentWithCheckpoints: ModuleItemContent = {
  id: '20',
  title: 'Discussion with Checkpoints',
  type: 'Discussion',
  pointsPossible: 10,
  checkpoints: defaultCheckpoints,
  replyToEntryRequiredCount: 2,
}

const setUp = (
  content: ModuleItemContent = defaultContent,
  completionRequirement: CompletionRequirement | null = defaultCompletionRequirement,
) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <ModuleItemSupplementalInfo
        content={content}
        completionRequirement={completionRequirement ?? undefined}
        contentTagId="19"
      />
    </ContextModuleProvider>,
  )
}

describe('ModuleItemSupplementalInfo', () => {
  it('renders', () => {
    const container = setUp()
    expect(container.container).toBeInTheDocument()
    expect(container.getAllByText('|')).toHaveLength(2)
  })

  it('does not render', () => {
    const container = setUp({...defaultContent, dueAt: undefined, pointsPossible: undefined}, null)
    expect(container.container).toBeInTheDocument()
    expect(
      container.queryByText(new Date(currentDate).toLocaleDateString()),
    ).not.toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  describe('due at', () => {
    it('renders', () => {
      const container = setUp(defaultContent, null)
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.getAllByText('|')).toHaveLength(1)
    })

    it('does not render', () => {
      const container = setUp({...defaultContent, dueAt: undefined})
      expect(container.container).toBeInTheDocument()
      expect(
        container.queryByText(new Date(currentDate).toLocaleDateString()),
      ).not.toBeInTheDocument()
      expect(container.queryAllByText('|')).toHaveLength(1)
    })
  })

  describe('points possible', () => {
    it('renders', () => {
      const container = setUp()
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('100 pts')).toBeInTheDocument()
    })

    it('does not render', () => {
      const container = setUp({...defaultContent, pointsPossible: undefined})
      expect(container.container).toBeInTheDocument()
      expect(container.queryByText('100 pts')).not.toBeInTheDocument()
    })
  })

  describe('discussion checkpoints', () => {
    it('renders checkpoints instead of regular due date', () => {
      const container = setUp(discussionContentWithCheckpoints, null)
      expect(container.container).toBeInTheDocument()

      // Should show checkpoint dates, not regular due date
      expect(container.getAllByTestId('checkpoint-due-date')).toHaveLength(2)
      expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
      expect(container.getByText(/Required Replies \(2\):/)).toBeInTheDocument()

      // Should not show regular due date
      expect(container.queryByTestId('due-date')).not.toBeInTheDocument()
    })

    it('renders multiple checkpoints with separators', () => {
      const container = setUp(discussionContentWithCheckpoints, null)

      // Should have separators between checkpoints
      expect(container.getAllByText('|')).toHaveLength(2) // One between checkpoints, one before points
      expect(container.getByText('10 pts')).toBeInTheDocument()
    })

    it('renders reply_to_topic checkpoint correctly', () => {
      const singleCheckpointContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [defaultCheckpoints[0]], // Only reply_to_topic
      }
      const container = setUp(singleCheckpointContent, null)

      expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
      expect(container.getByTestId('checkpoint-due-date')).toBeInTheDocument()
      expect(container.queryByText(/Required Replies/)).not.toBeInTheDocument()
    })

    it('renders reply_to_entry checkpoint with count', () => {
      const singleCheckpointContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [defaultCheckpoints[1]], // Only reply_to_entry
        replyToEntryRequiredCount: 3,
      }
      const container = setUp(singleCheckpointContent, null)

      expect(container.getByText(/Required Replies \(3\):/)).toBeInTheDocument()
      expect(container.getByTestId('checkpoint-due-date')).toBeInTheDocument()
    })

    it('renders reply_to_entry checkpoint without count', () => {
      const singleCheckpointContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [defaultCheckpoints[1]], // Only reply_to_entry
        replyToEntryRequiredCount: 0,
      }
      const container = setUp(singleCheckpointContent, null)

      expect(container.getByText(/Reply to Entry:/)).toBeInTheDocument()
      expect(container.queryByText(/Required Replies/)).not.toBeInTheDocument()
    })

    it('renders custom checkpoint name', () => {
      const customCheckpoint: Checkpoint = {
        dueAt: checkpointDate1,
        name: 'Custom Checkpoint Name',
        tag: 'custom',
      }
      const customContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [customCheckpoint],
      }
      const container = setUp(customContent, null)

      expect(container.getByText(/Custom Checkpoint Name:/)).toBeInTheDocument()
    })

    it('handles checkpoint with no due date', () => {
      const checkpointNoDue: Checkpoint = {
        name: 'No Due Date',
        tag: 'reply_to_topic',
      }
      const noDueContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [checkpointNoDue],
      }
      const container = setUp(noDueContent, null)

      expect(container.getByText(/Reply to Topic$/)).toBeInTheDocument()
      // When there's no due date, the component should still render but FriendlyDatetime handles null gracefully
      expect(container.container).toBeInTheDocument()
    })

    it('handles required replies checkpoint with no due date', () => {
      const checkpointNoDue: Checkpoint = {
        tag: 'reply_to_entry',
      }
      const noDueContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [checkpointNoDue],
        replyToEntryRequiredCount: 3,
      }
      const container = setUp(noDueContent, null)

      expect(container.getByText(/Required Replies \(3\)$/)).toBeInTheDocument()
      expect(container.queryByText(/Required Replies \(3\):/)).not.toBeInTheDocument()
    })

    it('handles custom checkpoint name with no due date', () => {
      const checkpointNoDue: Checkpoint = {
        name: 'Custom Name',
        tag: 'custom',
      }
      const noDueContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [checkpointNoDue],
      }
      const container = setUp(noDueContent, null)

      expect(container.getByText(/Custom Name$/)).toBeInTheDocument()
      expect(container.queryByText(/Custom Name:/)).not.toBeInTheDocument()
    })

    it('falls back to regular due date when no checkpoints', () => {
      const noCheckpointsContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [],
        dueAt: currentDate,
      }
      const container = setUp(noCheckpointsContent, null)

      // Should show regular due date
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.queryByTestId('checkpoint-due-date')).not.toBeInTheDocument()
    })

    it('shows points and completion requirements with checkpoints', () => {
      const container = setUp(discussionContentWithCheckpoints, defaultCompletionRequirement)

      expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
      expect(container.getByText(/Required Replies \(2\):/)).toBeInTheDocument()
      expect(container.getByText('10 pts')).toBeInTheDocument()

      // Should have separators: checkpoint1 | checkpoint2 | points | completion
      expect(container.getAllByText('|')).toHaveLength(3)
    })

    it('does not render when no content', () => {
      const container = setUp(null, null)
      expect(container.container.firstChild).toBeNull()
    })

    it('does not render when no checkpoints, due dates, points, or requirements', () => {
      const emptyContent: ModuleItemContent = {
        id: '21',
        title: 'Empty Content',
      }
      const container = setUp(emptyContent, null)
      expect(container.container.firstChild).toBeNull()
    })
  })
})
