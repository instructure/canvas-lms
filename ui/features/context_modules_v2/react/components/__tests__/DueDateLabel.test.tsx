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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import type {ModuleItemContent} from '../../utils/types'
import {format} from '@instructure/moment-utils'
import DueDateLabel from '../DueDateLabel'

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

const contentWithManyDueDates: ModuleItemContent = {
  ...defaultContent,
  assignedToDates: [
    {
      id: 'student_id_1',
      dueAt: new Date().addDays(-1).toISOString(), // # yesterday
      title: '1 student',
      set: {
        id: '1',
        type: 'ADHOC',
      },
    },
    {
      id: 'section_id',
      dueAt: new Date().addDays(1).toISOString(), // # tomorrow
      title: '1 section',
      set: {
        id: '1',
        type: 'CourseSection',
      },
    },
  ],
}

const contentWithConflictingAssignmentDueAt: ModuleItemContent = {
  id: '13',
  _id: '13',
  dueAt: '2024-01-18T23:59:59Z',
  assignedToDates: [
    {
      id: 'everyone',
      dueAt: '2024-01-15T23:59:59Z',
      title: 'Everyone',
      base: true,
    },
  ],
}

const setUp = (content: ModuleItemContent = defaultContent) => {
  return render(
    <ContextModuleProvider {...contextModuleDefaultProps}>
      <DueDateLabel content={content} contentTagId="19" />
    </ContextModuleProvider>,
  )
}

describe('DueDateLabel', () => {
  describe('with single due date', () => {
    it('renders', () => {
      const container = setUp()
      expect(container.container).toBeInTheDocument()
      expect(container.getByTestId('due-date')).toBeInTheDocument()
    })

    it('prefers assignedToDates for due date if it differs from dueAt', () => {
      const container = setUp(contentWithConflictingAssignmentDueAt)
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.getAllByText('Jan 15, 2024')[0]).toBeInTheDocument()
    })
  })
  describe('with multiple due dates', () => {
    it('renders', () => {
      const container = setUp(contentWithManyDueDates)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows tooltip with details upon hover', async () => {
      const container = setUp(contentWithManyDueDates)
      const dueAtFormat = '%b %-d at %l:%M%P'
      const dueDate1 = format(
        contentWithManyDueDates.assignedToDates?.[0].dueAt,
        dueAtFormat,
        undefined,
      ) as string
      const dueDate2 = format(
        contentWithManyDueDates.assignedToDates?.[1].dueAt,
        dueAtFormat,
        undefined,
      ) as string

      fireEvent.mouseOver(container.getByText('Multiple Due Dates'))

      await waitFor(() => container.getByTestId('override-details'))

      expect(container.getByTestId('override-details')).toHaveTextContent('1 student')
      expect(container.getByTestId('override-details').textContent).toContain(dueDate1)
      expect(container.getByTestId('override-details')).toHaveTextContent('1 section')
      expect(container.getByTestId('override-details').textContent).toContain(dueDate2)
    })
  })

  describe('graded discussion date handling', () => {
    const gradedDiscussionWithMultipleDates: ModuleItemContent = {
      id: '1',
      _id: '1',
      type: 'Discussion',
      graded: true,
      dueAt: '2024-01-15T23:59:59Z',
      assignment: {
        _id: 'assignment-1',
        dueAt: '2024-01-15T23:59:59Z',
      },
      assignedToDates: [
        {
          id: 'section-1',
          dueAt: '2024-01-16T23:59:59Z',
          title: 'Section 1',
          set: {id: '1', type: 'CourseSection'},
        },
        {
          id: 'section-2',
          dueAt: '2024-01-17T23:59:59Z',
          title: 'Section 2',
          set: {id: '2', type: 'CourseSection'},
        },
      ],
    }
    const gradedDiscussionWithOneDate: ModuleItemContent = {
      id: '13',
      _id: '13',
      type: 'Discussion',
      graded: true,
      assignment: {
        _id: 'assignment-13',
        dueAt: '2024-01-15T23:59:59Z',
      },
      assignedToDates: [
        {
          id: 'everyone',
          dueAt: '2024-01-15T23:59:59Z',
          title: 'Everyone',
          base: true,
        },
      ],
    }

    const gradedDiscussionWithCheckpointDate: ModuleItemContent = {
      id: '14',
      _id: '14',
      type: 'Discussion',
      graded: true,
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
      ],
      assignment: {
        _id: 'assignment-14',
      },
    }

    const gradedDiscussionWithMultipleCheckpointDates: ModuleItemContent = {
      id: '14',
      _id: '14',
      type: 'Discussion',
      graded: true,
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
            {
              id: 'section-1',
              dueAt: '2024-01-21T23:59:59Z',
              title: 'Section 1',
              set: {
                id: '1',
                type: 'CourseSection',
              },
            },
          ],
        },
      ],
      assignment: {
        _id: 'assignment-14',
      },
    }

    it('shows multiple due dates for graded discussion with multiple assign to dates', () => {
      const container = setUp(gradedDiscussionWithMultipleDates)
      expect(container.container).toBeInTheDocument()
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
      // Should show "Multiple Due Dates" link for discussions with assignment-level overrides
      expect(container.queryByText('Multiple Due Dates')).toBeInTheDocument()
    })

    it('shows one due date for graded discussion with one assign to date', () => {
      const container = setUp(gradedDiscussionWithOneDate)
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
    })

    it('shows single date for checkpointed discussion with single date', () => {
      const container = setUp(gradedDiscussionWithCheckpointDate.checkpoints?.[0])
      expect(container.getByTestId('due-date')).toBeInTheDocument()
      expect(container.queryByText('Multiple Due Dates')).not.toBeInTheDocument()
    })

    it('shows multiple dates for checkpointed discussion with multiple dates', () => {
      const container = setUp(gradedDiscussionWithMultipleCheckpointDates.checkpoints?.[0])
      expect(container.getByText('Multiple Due Dates')).toBeInTheDocument()
    })

    describe('edge cases', () => {
      const discussionWithNullDates: ModuleItemContent = {
        id: '17',
        _id: '17',
        type: 'Discussion',
        graded: false,
        todoDate: undefined,
        lockAt: undefined,
        dueAt: undefined,
        assignedToDates: [],
      }

      it('returns null when discussion has no dates', () => {
        const container = setUp(discussionWithNullDates)
        expect(container.container.firstChild).toBeNull()
      })
    })
  })
})
