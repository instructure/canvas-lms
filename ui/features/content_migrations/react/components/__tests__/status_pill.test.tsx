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
import StatusPill, {getColor} from '../status_pill'

describe('StatusPill', () => {
  describe('when the workflowState is running', () => {
    const workflowState = 'running'

    it('renders the Running text', () => {
      render(<StatusPill workflowState={workflowState} hasIssues={false} />)
      expect(screen.getByText('Running')).toBeInTheDocument()
    })

    it('renders with the info color', () => {
      const color = getColor({workflowState, hasIssues: false})
      expect(color).toEqual('info')
    })
  })

  describe('when the workflowState is failed', () => {
    const workflowState = 'failed'

    it('renders the Failed text', () => {
      render(<StatusPill workflowState={workflowState} hasIssues={false} />)
      expect(screen.getByText('Failed')).toBeInTheDocument()
    })

    it('renders with the danger color', () => {
      const color = getColor({workflowState, hasIssues: false})
      expect(color).toEqual('danger')
    })
  })

  describe('when the workflowState is completed', () => {
    const workflowState = 'completed'

    describe('when there was no issue', () => {
      const hasIssues = false

      it('renders with the success color', () => {
        const color = getColor({workflowState, hasIssues})
        expect(color).toEqual('success')
      })

      it('renders the Completed text', () => {
        render(<StatusPill workflowState={workflowState} hasIssues={hasIssues} />)
        expect(screen.getByText('Completed')).toBeInTheDocument()
      })
    })

    describe('when there was issue', () => {
      const hasIssues = true

      it('renders with the warning color', () => {
        const color = getColor({workflowState, hasIssues})
        expect(color).toEqual('warning')
      })

      it('renders the Partially Completed text', () => {
        render(<StatusPill workflowState={workflowState} hasIssues={hasIssues} />)
        expect(screen.getByText('Partially Completed')).toBeInTheDocument()
      })
    })
  })

  describe('when the workflowState is queued', () => {
    const workflowState = 'queued'

    it('renders the Queued text', () => {
      render(<StatusPill workflowState={workflowState} hasIssues={false} />)
      expect(screen.getByText('Queued')).toBeInTheDocument()
    })

    it('renders with the primary color', () => {
      const color = getColor({workflowState, hasIssues: false})
      expect(color).toEqual('primary')
    })
  })

  describe('when the workflowState is waiting_for_select', () => {
    const workflowState = 'waiting_for_select'

    it('renders the correct text', () => {
      render(<StatusPill workflowState={workflowState} hasIssues={false} />)
      expect(screen.getByText('Waiting for selection')).toBeInTheDocument()
    })

    it('renders with the primary color', () => {
      const color = getColor({workflowState, hasIssues: false})
      expect(color).toEqual('primary')
    })
  })
})
