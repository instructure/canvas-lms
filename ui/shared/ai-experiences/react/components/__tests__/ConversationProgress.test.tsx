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
import userEvent from '@testing-library/user-event'
import ConversationProgress from '../ConversationProgress'

describe('ConversationProgress', () => {
  const mockProgress = {
    current: 2,
    total: 4,
    percentage: 50,
    objectives: [
      {objective: 'Learn React basics', status: 'covered' as 'covered' | ''},
      {objective: 'Understand hooks', status: 'covered' as 'covered' | ''},
      {objective: 'Master state management', status: '' as 'covered' | ''},
      {objective: 'Build components', status: '' as 'covered' | ''},
    ],
  }

  it('renders progress bar with correct percentage', () => {
    render(<ConversationProgress progress={mockProgress} />)
    expect(screen.getByText('50%')).toBeInTheDocument()
  })

  it('renders null when progress is null', () => {
    const {container} = render(<ConversationProgress progress={null} />)
    expect(container.firstChild).toBeNull()
  })

  it('shows objectives in popover', async () => {
    const user = userEvent.setup()
    const {container} = render(<ConversationProgress progress={mockProgress} />)

    // Find the button that contains the percentage text
    const button = container.querySelector('button')
    expect(button).not.toBeNull()
    await user.click(button!)

    expect(screen.getByText(/Learning objectives covered:/i)).toBeInTheDocument()
    expect(screen.getByText(/Learn React basics/)).toBeInTheDocument()
    expect(screen.getByText(/Understand hooks/)).toBeInTheDocument()
    expect(screen.getByText(/Master state management/)).toBeInTheDocument()
    expect(screen.getByText(/Build components/)).toBeInTheDocument()
  })

  it('shows checkmark icon for covered objectives', async () => {
    const user = userEvent.setup()
    const {container} = render(<ConversationProgress progress={mockProgress} />)

    // Find the button that contains the percentage text
    const button = container.querySelector('button')
    expect(button).not.toBeNull()
    await user.click(button!)

    expect(screen.getByText(/Learn React basics/)).toBeInTheDocument()
    expect(screen.getByText(/Understand hooks/)).toBeInTheDocument()
  })

  it('displays 0% for zero progress', () => {
    const zeroProgress = {
      current: 0,
      total: 3,
      percentage: 0,
      objectives: [
        {objective: 'Objective 1', status: '' as 'covered' | ''},
        {objective: 'Objective 2', status: '' as 'covered' | ''},
        {objective: 'Objective 3', status: '' as 'covered' | ''},
      ],
    }

    render(<ConversationProgress progress={zeroProgress} />)
    expect(screen.getByText('0%')).toBeInTheDocument()
  })

  it('displays 100% for complete progress', () => {
    const completeProgress = {
      current: 3,
      total: 3,
      percentage: 100,
      objectives: [
        {objective: 'Objective 1', status: 'covered' as 'covered' | ''},
        {objective: 'Objective 2', status: 'covered' as 'covered' | ''},
        {objective: 'Objective 3', status: 'covered' as 'covered' | ''},
      ],
    }

    render(<ConversationProgress progress={completeProgress} />)
    expect(screen.getByText('100%')).toBeInTheDocument()
  })

  it('has accessible label for screen readers', () => {
    render(<ConversationProgress progress={mockProgress} />)
    expect(screen.getByLabelText(/Learning objective progress: 50%/i)).toBeInTheDocument()
  })
})
