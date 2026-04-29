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
  dueAt: currentDate,
  pointsPossible: 100,
  assignedToDates: [
    {
      id: 'everyone',
      dueAt: currentDate,
      title: 'Everyone',
      base: true,
    },
  ],
}

const checkpointDate1 = new Date('2024-01-20T23:59:00Z').toISOString()
const checkpointDate2 = new Date('2024-01-22T23:59:00Z').toISOString()

const defaultCheckpoints: Checkpoint[] = [
  {
    dueAt: checkpointDate1,
    name: 'Reply to Topic',
    tag: 'reply_to_topic',
    assignedToDates: [
      {
        id: 'everyone',
        dueAt: checkpointDate1,
        title: 'Everyone',
        base: true,
      },
    ],
  },
  {
    dueAt: checkpointDate2,
    name: 'Required Replies',
    tag: 'reply_to_entry',
    assignedToDates: [
      {
        id: 'everyone',
        dueAt: checkpointDate2,
        title: 'Everyone',
        base: true,
      },
    ],
  },
]

const discussionContentWithCheckpoints: ModuleItemContent = {
  id: '20',
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
      const container = setUp({...defaultContent, dueAt: undefined, assignedToDates: []})
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
      expect(container.getAllByTestId('due-date')).toHaveLength(2)
      expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
      expect(container.getByText(/Required Replies \(2\):/)).toBeInTheDocument()

      // Should show checkpoint due dates (which use the same testid as regular due dates)
      expect(container.queryAllByTestId('due-date')).toHaveLength(2)
    })

    it('renders multiple checkpoints with separators', () => {
      const container = setUp(discussionContentWithCheckpoints, null)

      // Should have separators between checkpoints
      expect(container.getAllByText('|')).toHaveLength(2)
      expect(container.getByText('10 pts')).toBeInTheDocument()
    })

    it('renders reply_to_topic checkpoint correctly', () => {
      const singleCheckpointContent = {
        ...discussionContentWithCheckpoints,
        checkpoints: [defaultCheckpoints[0]], // Only reply_to_topic
      }
      const container = setUp(singleCheckpointContent, null)

      expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
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
      expect(container.getByTestId('due-date')).toBeInTheDocument()
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
        assignedToDates: [
          {
            id: 'everyone',
            dueAt: checkpointDate1,
            title: 'Everyone',
            base: true,
          },
        ],
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
      }
      const container = setUp(emptyContent, null)
      expect(container.container.firstChild).toBeNull()
    })
  })

  describe('discussion date handling integration', () => {
    const gradedDiscussionWithOneDate: ModuleItemContent = {
      id: '24',
      type: 'Discussion',
      graded: true,
      assignment: {
        _id: 'assignment-24',
        dueAt: '2024-01-15T23:59:59Z',
      },
      pointsPossible: 10,
      assignedToDates: [
        {
          id: 'everyone',
          dueAt: '2024-01-15T23:59:59Z',
          title: 'Everyone',
          base: true,
        },
      ],
    }

    const gradedDiscussionWithMultipleDates: ModuleItemContent = {
      id: '26',
      type: 'Discussion',
      graded: true,
      assignedToDates: [
        {
          id: 'everyone',
          dueAt: '2024-01-15T23:59:59Z',
          title: 'Everyone',
          base: true,
        },
        {
          id: 'section-1',
          dueAt: '2024-01-16T23:59:59Z',
          title: 'Section 1',
          set: {
            id: '1',
            type: 'CourseSection',
          },
        },
      ],
      pointsPossible: 20,
    }

    const checkpointDiscussionWithMixedDates: ModuleItemContent = {
      id: '27',
      type: 'Discussion',
      pointsPossible: 25,
      checkpoints: [
        {
          dueAt: '2024-01-20T23:59:59Z',
          name: 'Reply to Topic',
          tag: 'reply_to_topic',
          assignedToDates: [
            {
              id: 'everyone',
              dueAt: '2024-01-20T23:59:59Z',
              title: 'Everyone',
              base: true,
            },
          ],
        },
        {
          dueAt: '2024-01-22T23:59:59Z',
          name: 'Required Replies',
          tag: 'reply_to_entry',
          assignedToDates: [
            {
              id: 'everyone',
              dueAt: '2024-01-22T23:59:59Z',
              title: 'Everyone',
              base: true,
            },
          ],
        },
      ],
      replyToEntryRequiredCount: 3,
      assignment: {
        _id: 'assignment-27',
        dueAt: '2024-01-18T23:59:59Z',
      },
    }

    describe('graded discussion date handling', () => {
      it('displays assignment.dueAt for graded discussion', () => {
        const container = setUp(gradedDiscussionWithOneDate, null)
        expect(container.getByTestId('due-date')).toBeInTheDocument()
        expect(container.getByText('10 pts')).toBeInTheDocument()
        expect(container.getAllByText('|')).toHaveLength(1)
      })

      it('integrates with standardized dates', () => {
        const container = setUp(gradedDiscussionWithMultipleDates, null)
        expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
        expect(container.getByText('20 pts')).toBeInTheDocument()
        expect(container.getAllByText('|')).toHaveLength(1)
      })

      it('shows single date for single standardized date', () => {
        const singleDateContent = {
          ...gradedDiscussionWithMultipleDates,
          assignedToDates: [gradedDiscussionWithMultipleDates.assignedToDates![0]],
        }
        const container = setUp(singleDateContent, null)
        expect(container.getByTestId('due-date')).toBeInTheDocument()
        expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        expect(container.getByText('20 pts')).toBeInTheDocument()
      })
    })

    describe('checkpoint discussion integration', () => {
      it('prioritizes checkpoints over assignment dates', () => {
        const container = setUp(checkpointDiscussionWithMixedDates, null)

        // Should show checkpoints, not assignment dates
        expect(container.getAllByTestId('due-date')).toHaveLength(2)
        expect(container.getByText(/Reply to Topic:/)).toBeInTheDocument()
        expect(container.getByText(/Required Replies \(3\):/)).toBeInTheDocument()

        // Should not show Multiple Due Dates even though assignment has overrides
        expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()

        // Should show points
        expect(container.getByText('25 pts')).toBeInTheDocument()

        // Should have separators: checkpoint1 | checkpoint2 | points
        expect(container.getAllByText('|')).toHaveLength(2)
      })

      it('handles checkpoint discussion with completion requirement', () => {
        const completionReq: CompletionRequirement = {
          id: '27',
          type: 'must_view',
          completed: false,
        }
        const container = setUp(checkpointDiscussionWithMixedDates, completionReq)

        expect(container.getAllByTestId('due-date')).toHaveLength(2)
        expect(container.getByText('25 pts')).toBeInTheDocument()

        // Should have separators: checkpoint1 | checkpoint2 | points | completion
        expect(container.getAllByText('|')).toHaveLength(3)
      })
    })

    describe('edge cases and error handling', () => {
      const discussionWithNoDates: ModuleItemContent = {
        id: '28',
        type: 'Discussion',
        graded: false,
        pointsPossible: 5,
      }

      const discussionWithMalformedData: ModuleItemContent = {
        id: '30',
        type: 'Discussion',
        graded: true,
        assignment: {
          _id: 'assignment-30',
          // Missing dueAt
        },
        assignedToDates: [], // Empty standardized dates
        pointsPossible: 15,
      }

      const assignmentWithNoDueDate: ModuleItemContent = {
        id: '15',
        type: 'Assignment',
        pointsPossible: 10,
        assignedToDates: [
          {
            id: '123',
            unlockAt: '2025-08-22T00:00:00-06:00',
            lockAt: '2025-08-24T23:59:59-06:00',
            title: 'Everyone',
            base: true,
          },
        ],
      }

      it('handles discussion with no dates gracefully', () => {
        const container = setUp(discussionWithNoDates, null)
        expect(container.getByText('5 pts')).toBeInTheDocument()
        expect(container.queryByTestId('due-date')).not.toBeInTheDocument()
        expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
        expect(container.queryAllByText('|')).toHaveLength(0) // No separators when only points
      })

      it('handles malformed discussion data', () => {
        const container = setUp(discussionWithMalformedData, null)
        expect(container.getByText('15 pts')).toBeInTheDocument()
        expect(container.queryByTestId('due-date')).not.toBeInTheDocument()
        expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
      })

      it('does not render the due dates container when due date is empty', () => {
        const container = setUp(assignmentWithNoDueDate, null)
        expect(container.getByText('10 pts')).toBeInTheDocument()
        expect(container.queryByTestId('due-date')).not.toBeInTheDocument()
        expect(container.queryAllByText('|')).toHaveLength(0)
      })
    })

    describe('integration with completion requirements', () => {
      const completionReq: CompletionRequirement = {
        id: '31',
        type: 'must_view',
        completed: true,
      }

      it('shows all components for discussion with dates, points, and completion', () => {
        const container = setUp(gradedDiscussionWithOneDate, completionReq)
        expect(container.getByTestId('due-date')).toBeInTheDocument()
        expect(container.getByText('10 pts')).toBeInTheDocument()

        // Should have separators: date | points | completion
        expect(container.getAllByText('|')).toHaveLength(2)
      })

      it('shows completion without dates for discussion', () => {
        const discussionNoDates = {
          id: '32',
          type: 'Discussion' as const,
          graded: true,
          pointsPossible: 8,
        }
        const container = setUp(discussionNoDates, completionReq)
        expect(container.getByText('8 pts')).toBeInTheDocument()
        expect(container.queryByTestId('due-date')).not.toBeInTheDocument()

        // Should have separator: points | completion
        expect(container.getAllByText('|')).toHaveLength(1)
      })
    })
  })
})
