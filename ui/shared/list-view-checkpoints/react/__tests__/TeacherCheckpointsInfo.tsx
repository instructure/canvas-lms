/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

// Mock the I18n function
jest.mock('@canvas/i18n', () => ({
  useScope: () => ({
    t: (str: string) => str,
    n: (num: number) => num.toString(),
  }),
}))

// Mock assignments
const assignmentNoDueDates = {
  id: '1',
  checkpoints: [
    {tag: 'reply_to_topic', due_at: null, overrides: []},
    {tag: 'reply_to_entry', due_at: null, overrides: []},
  ],
  discussion_topic: {
    reply_to_entry_required_count: 4,
  },
}

const assignmentWithDueDates = {
  id: '2',
  checkpoints: [
    {tag: 'reply_to_topic', due_at: '2024-06-02T00:00:00Z', overrides: []},
    {tag: 'reply_to_entry', due_at: '2024-06-04T00:00:00Z', overrides: []},
  ],
  discussion_topic: {
    reply_to_entry_required_count: 4,
  },
}

const assignmentWithOverrides = {
  id: '3',
  checkpoints: [
    {
      tag: 'reply_to_topic',
      due_at: '2024-06-02T00:00:00Z',
      overrides: [
        {title: 'Section 1', due_at: '2024-06-03T00:00:00Z'},
        {title: 'Section 2', due_at: '2024-06-04T00:00:00Z'},
      ],
    },
    {
      tag: 'reply_to_entry',
      due_at: '2024-06-04T00:00:00Z',
      overrides: [
        {title: 'Section 1', due_at: '2024-06-05T00:00:00Z'},
        {title: 'Section 2', due_at: '2024-06-06T00:00:00Z'},
      ],
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

      expect(screen.getByText('Jun 2')).toBeInTheDocument()
      expect(screen.getByText('Jun 4')).toBeInTheDocument()
    })

    it('displays "Multiple Dates" when checkpoints have overrides', () => {
      render(<TeacherCheckpointsInfo assignment={assignmentWithOverrides} />)

      expect(screen.getAllByText('Multiple Dates')).toHaveLength(2)
    })
  })

  describe('tooltip', () => {
    it('shows tooltip with correct dates on hover', async () => {
      render(<TeacherCheckpointsInfo assignment={assignmentWithOverrides} />)

      const multipleDatesLinks = screen.getAllByText('Multiple Dates')
      await userEvent.hover(multipleDatesLinks[0])

      expect(screen.getByText('Section 1')).toBeInTheDocument()
      expect(screen.getByText('Jun 3')).toBeInTheDocument()
      expect(screen.getByText('Section 2')).toBeInTheDocument()
      expect(screen.getByText('Jun 4')).toBeInTheDocument()
      expect(screen.getByText('Everyone else')).toBeInTheDocument()
      expect(screen.getByText('Jun 2')).toBeInTheDocument()
    })
  })
})
