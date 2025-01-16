/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {TeacherCheckpointsInfo} from '../TeacherCheckpointsInfo'

// Mock assignments
const assignmentNoDueDates = {
  id: '1',
  points_possible: 20,
  checkpoints: [
    {
      tag: 'reply_to_topic',
      due_at: null,
      overrides: [],
      lock_at: null,
      unlock_at: null,
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
    {
      tag: 'reply_to_entry',
      due_at: null,
      overrides: [],
      lock_at: null,
      unlock_at: null,
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
  ],
  discussion_topic: {
    reply_to_entry_required_count: 4,
  },
}

const assignmentWithDueDates = {
  id: '2',
  points_possible: 20,
  checkpoints: [
    {
      tag: 'reply_to_topic',
      due_at: '2023-06-02T12:00:00Z',
      overrides: [],
      lock_at: '2023-07-02T12:00:00Z',
      unlock_at: '2023-05-02T12:00:00Z',
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
    {
      tag: 'reply_to_entry',
      due_at: '2023-06-04T12:00:00Z',
      overrides: [],
      lock_at: '2023-07-02T12:00:00Z',
      unlock_at: '2023-05-02T12:00:00Z',
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
  ],
  discussion_topic: {
    reply_to_entry_required_count: 4,
  },
}

const assignmentWithOverrides = {
  id: '3',
  points_possible: 20,
  checkpoints: [
    {
      tag: 'reply_to_topic',
      due_at: '2023-06-02T12:00:00Z',
      overrides: [
        {
          title: 'Section 1',
          due_at: '2023-06-03T12:00:00Z',
          lock_at: '2023-07-03T12:00:00Z',
          unlock_at: '2023-05-03T12:00:00Z',
          all_day: true,
          all_day_date: '',
          assignment_id: '3',
          id: '',
          unassign_item: false,
          student_ids: ['1'],
        },
        {
          title: 'Section 2',
          due_at: '2023-06-04T12:00:00Z',
          lock_at: '2023-07-03T12:00:00Z',
          unlock_at: '2023-05-03T12:00:00Z',
          all_day: true,
          all_day_date: '',
          assignment_id: '3',
          id: '',
          unassign_item: false,
          student_ids: ['1'],
        },
      ],
      lock_at: '2023-07-02T12:00:00Z',
      unlock_at: '2023-05-02T12:00:00Z',
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
    {
      tag: 'reply_to_entry',
      due_at: '2023-06-07T12:00:00Z',
      overrides: [
        {
          title: 'Section 1',
          due_at: '2023-06-05T12:00:00Z',
          lock_at: '2023-07-03T12:00:00Z',
          unlock_at: '2023-05-03T12:00:00Z',
          all_day: true,
          all_day_date: '',
          assignment_id: '3',
          id: '',
          unassign_item: false,
          student_ids: ['1'],
        },
        {
          title: 'Section 2',
          due_at: '2023-06-06T12:00:00Z',
          lock_at: '2023-07-03T12:00:00Z',
          unlock_at: '2023-05-03T12:00:00Z',
          all_day: true,
          all_day_date: '',
          assignment_id: '3',
          id: '',
          unassign_item: false,
          student_ids: ['1'],
        },
      ],
      lock_at: '2023-07-02T12:00:00Z',
      unlock_at: '2023-05-02T12:00:00Z',
      name: '',
      points_possible: 10,
      only_visible_to_overrides: false,
    },
  ],
  discussion_topic: {
    reply_to_entry_required_count: 4,
  },
}

describe('TeacherCheckpointsInfo', () => {
  it('renders the component with correct checkpoint titles', () => {
    render(<TeacherCheckpointsInfo assignment={assignmentNoDueDates} />)

    expect(screen.getByText('Reply to Topic:')).toBeInTheDocument()
    expect(screen.getByText('Required Replies (4):')).toBeInTheDocument()
  })

  describe('due dates', () => {
    it('displays "No Due Date" when checkpoints have no due dates', () => {
      render(<TeacherCheckpointsInfo assignment={assignmentNoDueDates} />)

      expect(screen.getAllByText('No Due Date')).toHaveLength(2)
    })

    it('displays formatted due dates when checkpoints have due dates', () => {
      render(<TeacherCheckpointsInfo assignment={assignmentWithDueDates} />)

      expect(screen.getByText('Jun 2, 2023 at 12pm')).toBeInTheDocument()
      expect(screen.getByText('Jun 4, 2023 at 12pm')).toBeInTheDocument()
    })

    it('displays "Multiple Dates" when checkpoints have overrides', () => {
      render(<TeacherCheckpointsInfo assignment={assignmentWithOverrides} />)

      expect(screen.getAllByText('Multiple Dates')).toHaveLength(3)
    })
  })
  describe('availability dates', () => {
    it('does not show the availability for the row', () => {
      const {queryByText} = render(<TeacherCheckpointsInfo assignment={assignmentNoDueDates} />)

      expect(queryByText('Available Until:')).not.toBeInTheDocument()
      expect(queryByText('Not Available Until:')).not.toBeInTheDocument()
      expect(queryByText('Availability:')).not.toBeInTheDocument()
    })
    it('shows the availability for the row', () => {
      const {queryByText, queryByTestId} = render(
        <TeacherCheckpointsInfo assignment={assignmentWithDueDates} />,
      )

      expect(queryByTestId('2_cp_availability')).toBeInTheDocument()
      expect(queryByText('Available Until:')).toBeInTheDocument()
      expect(queryByText('Availability:')).not.toBeInTheDocument()
    })
    it('shows multiple availability dates for the row', () => {
      const {queryByText, queryByTestId} = render(
        <TeacherCheckpointsInfo assignment={assignmentWithOverrides} />,
      )

      expect(queryByTestId('3_cp_availability')).toBeInTheDocument()
      expect(queryByText('Available Until:')).not.toBeInTheDocument()
      expect(queryByText('Availability:')).toBeInTheDocument()
      expect(screen.getAllByText('Multiple Dates')).toHaveLength(3)
    })
  })

  describe('tooltip', () => {
    it('shows tooltip with correct dates on hover', async () => {
      render(<TeacherCheckpointsInfo assignment={assignmentWithOverrides} />)

      const multipleDatesLinks = screen.getAllByText('Multiple Dates')
      await userEvent.hover(multipleDatesLinks[0])

      expect(screen.getAllByText('Section 1')).toHaveLength(2)
      expect(screen.getAllByText('Section 2')).toHaveLength(2)
      expect(screen.getAllByText('Everyone else')).toHaveLength(2)

      // reply_to_topic due dates
      expect(screen.getByText('Jun 3, 2023 at 12pm')).toBeInTheDocument() // Section 1
      expect(screen.getByText('Jun 4, 2023 at 12pm')).toBeInTheDocument() // Section 2
      expect(screen.getByText('Jun 2, 2023 at 12pm')).toBeInTheDocument() // Everyone else

      // reply_to_entry due dates
      expect(screen.getByText('Jun 5, 2023 at 12pm')).toBeInTheDocument() // Section 1
      expect(screen.getByText('Jun 6, 2023 at 12pm')).toBeInTheDocument() // Section 2
      expect(screen.getByText('Jun 7, 2023 at 12pm')).toBeInTheDocument() // Everyone else
    })
  })

  describe('points possible', () => {
    it('display points possible for checkpoint', () => {
      const {queryByText, queryByTestId} = render(
        <TeacherCheckpointsInfo assignment={assignmentNoDueDates} />,
      )

      expect(queryByText('20 pts')).toBeInTheDocument()
      expect(queryByTestId('1_points_possible')).toBeInTheDocument()
    })
  })
})
