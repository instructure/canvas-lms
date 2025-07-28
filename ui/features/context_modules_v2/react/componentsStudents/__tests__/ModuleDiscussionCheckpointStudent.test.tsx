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
import {render, screen} from '@testing-library/react'
import ModuleDiscussionCheckpointStudent from '../ModuleDiscussionCheckpointStudent'
import {Checkpoint, ModuleItemContent} from '../../utils/types'

describe('ModuleDiscussionCheckpointStudent', () => {
  beforeAll(() => {
    window.ENV = window.ENV || {}
    window.ENV.TIMEZONE = 'America/Denver'
  })

  const defaultContent = {
    id: 'discussion-1',
    title: 'Discussion Title',
    htmlUrl: '/courses/1/discussions/1',
    type: 'Discussion',
  } as ModuleItemContent

  const defaultCheckpoints: Checkpoint[] = [
    {
      name: 'Discussion Checkpoint',
      tag: 'reply_to_topic',
      dueAt: '2025-06-10T23:59:59Z',
    },
    {
      name: 'Reply Checkpoint',
      tag: 'reply_to_entry',
      dueAt: '2025-06-11T23:59:59Z',
    },
  ]

  it('renders nothing when content is not provided', () => {
    render(<ModuleDiscussionCheckpointStudent checkpoints={defaultCheckpoints} />)
    expect(screen.queryByTestId('module-discussion-checkpoint')).not.toBeInTheDocument()
  })

  it('renders nothing when checkpoints are not provided', () => {
    render(<ModuleDiscussionCheckpointStudent content={defaultContent} />)
    expect(screen.queryByTestId('module-discussion-checkpoint')).not.toBeInTheDocument()
  })

  it('renders checkpoints with due dates', () => {
    render(
      <ModuleDiscussionCheckpointStudent
        content={defaultContent}
        checkpoints={defaultCheckpoints}
      />,
    )

    const checkpointContainer = screen.getByTestId('module-discussion-checkpoint')
    expect(checkpointContainer).toBeInTheDocument()

    const dueDates = screen.getAllByTestId('due-date')
    expect(dueDates).toHaveLength(2)

    expect(screen.getByText('|')).toBeInTheDocument()
  })

  it('formats reply_to_topic checkpoint description correctly', () => {
    const checkpoints: Checkpoint[] = [
      {
        name: 'Ignore this name',
        tag: 'reply_to_topic',
        dueAt: '2025-06-10T23:59:59Z',
      },
    ]

    render(<ModuleDiscussionCheckpointStudent content={defaultContent} checkpoints={checkpoints} />)

    expect(screen.getByText(/Reply to Topic:/)).toBeInTheDocument()
  })

  it('formats reply_to_entry checkpoint with required count correctly', () => {
    const checkpoints = [
      {
        name: 'Reply Checkpoint',
        tag: 'reply_to_entry',
        dueAt: '2025-06-11T23:59:59Z',
      },
    ] as Checkpoint[]

    render(
      <ModuleDiscussionCheckpointStudent
        content={defaultContent}
        checkpoints={checkpoints}
        replyToEntryRequiredCount={3}
      />,
    )

    expect(screen.getByText(/Required Replies \(3\):/)).toBeInTheDocument()
  })

  it('formats reply_to_entry checkpoint without required count correctly', () => {
    const checkpoints = [
      {
        name: 'Reply Checkpoint',
        tag: 'reply_to_entry',
        dueAt: '2025-06-11T23:59:59Z',
      },
    ] as Checkpoint[]

    render(<ModuleDiscussionCheckpointStudent content={defaultContent} checkpoints={checkpoints} />)

    expect(screen.getByText(/Reply to Entry/)).toBeInTheDocument()
  })

  it('uses checkpoint name for unknown tags', () => {
    const checkpoints: Checkpoint[] = [
      {
        name: 'Custom Checkpoint',
        tag: 'custom_tag',
        dueAt: '2025-06-12T23:59:59Z',
      },
    ]

    render(<ModuleDiscussionCheckpointStudent content={defaultContent} checkpoints={checkpoints} />)

    expect(screen.getByText('Custom Checkpoint')).toBeInTheDocument()
  })

  it('shows empty string for unknown tags with no name', () => {
    const checkpoints: Checkpoint[] = [
      {
        tag: 'custom_tag',
        dueAt: '2025-06-12T23:59:59Z',
      },
    ]

    render(<ModuleDiscussionCheckpointStudent content={defaultContent} checkpoints={checkpoints} />)

    expect(screen.getByTestId('module-discussion-checkpoint')).toBeInTheDocument()
    expect(screen.getByTestId('due-date')).toBeInTheDocument()
  })

  it('renders multiple checkpoints with separators between them', () => {
    const checkpoints: Checkpoint[] = [
      {
        name: 'First Checkpoint',
        tag: 'reply_to_topic',
        dueAt: '2025-06-10T23:59:59Z',
      },
      {
        name: 'Second Checkpoint',
        tag: 'reply_to_entry',
        dueAt: '2025-06-11T23:59:59Z',
      },
      {
        name: 'Third Checkpoint',
        tag: 'custom_tag',
        dueAt: '2025-06-12T23:59:59Z',
      },
    ]

    render(<ModuleDiscussionCheckpointStudent content={defaultContent} checkpoints={checkpoints} />)

    expect(screen.getAllByTestId('due-date')).toHaveLength(3)
    const separators = screen.getAllByText('|')
    expect(separators).toHaveLength(2)
  })
})
