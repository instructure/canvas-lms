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
import StatusPill from '../status_pill'

describe('StatusPill', () => {
  describe('when the workflowState is pre_processing', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="pre_processing" hasIssues={false} />)
      expect(screen.getByText('Created')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is running', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="running" hasIssues={false} />)
      expect(screen.getByText('Running')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is failed', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="failed" hasIssues={false} />)
      expect(screen.getByText('Failed')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is completed', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="completed" hasIssues={false} />)
      expect(screen.getByText('Completed')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is queued', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="queued" hasIssues={false} />)
      expect(screen.getByText('Queued')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is pre_processed', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="pre_processed" hasIssues={false} />)
      expect(screen.getByText('Running')).toBeInTheDocument()
    })
  })

  describe('when the workflowState is waiting_for_select', () => {
    it('renders the correct text', () => {
      render(<StatusPill workflowState="waiting_for_select" hasIssues={false} />)
      expect(screen.getByText('Waiting for selection')).toBeInTheDocument()
    })
  })
})
