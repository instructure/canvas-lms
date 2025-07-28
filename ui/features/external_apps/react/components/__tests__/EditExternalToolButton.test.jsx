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
import EditExternalToolButton from '../EditExternalToolButton'
import store from '../../lib/ExternalAppsStore'

jest.mock('../../lib/ExternalAppsStore', () => ({
  fetchWithDetails: jest.fn(),
  fetch: jest.fn(),
}))

describe('EditExternalToolButton', () => {
  const defaultProps = {
    tool: {name: 'test tool'},
    canEdit: true,
    returnFocus: () => {},
  }

  beforeEach(() => {
    window.ENV = {APP_CENTER: {enabled: true}}
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('allows editing of tools when canEdit is true', () => {
    render(<EditExternalToolButton {...defaultProps} />)
    expect(
      screen.queryByText('This action has been disabled by your admin.'),
    ).not.toBeInTheDocument()
  })

  it('opens modal with expected tool state', async () => {
    const tool = {
      name: 'test tool',
      description: 'New tool description',
      app_type: 'ContextExternalTool',
    }

    store.fetchWithDetails.mockResolvedValue({
      name: 'test tool',
      description: 'New tool description',
      privacy_level: 'public',
    })

    render(<EditExternalToolButton {...defaultProps} tool={tool} />)
    const editButton = screen.getByRole('menuitem', {name: /edit.*app/i})
    await userEvent.click(editButton)

    expect(store.fetchWithDetails).toHaveBeenCalledWith(tool)
  })

  it('sets new state from store response', async () => {
    store.fetchWithDetails.mockResolvedValue({
      name: 'New Name',
      description: 'Current State',
      privacy_level: 'public',
    })

    const tool = {
      name: 'Old Name',
      description: 'Old State',
      app_type: 'ContextExternalTool',
    }

    render(<EditExternalToolButton {...defaultProps} tool={tool} />)
    const editButton = screen.getByRole('menuitem', {name: /edit.*app/i})
    await userEvent.click(editButton)

    expect(store.fetchWithDetails).toHaveBeenCalledWith(tool)
  })

  it('allows editing of tools with granular permissions', () => {
    render(<EditExternalToolButton {...defaultProps} canEdit={true} />)
    expect(
      screen.queryByText('This action has been disabled by your admin.'),
    ).not.toBeInTheDocument()
  })

  it('opens modal with expected tool state with granular permissions', async () => {
    const tool = {
      name: 'test tool',
      description: 'New tool description',
      app_type: 'ContextExternalTool',
    }

    store.fetchWithDetails.mockResolvedValue({
      name: 'test tool',
      description: 'New tool description',
      privacy_level: 'public',
    })

    render(<EditExternalToolButton {...defaultProps} tool={tool} canEdit={true} />)
    const editButton = screen.getByRole('menuitem', {name: /edit.*app/i})
    await userEvent.click(editButton)

    expect(store.fetchWithDetails).toHaveBeenCalledWith(tool)
  })

  it('sets new state from store response with granular permissions', async () => {
    store.fetchWithDetails.mockResolvedValue({
      name: 'New Name',
      description: 'Current State',
      privacy_level: 'public',
    })

    const tool = {
      name: 'Old Name',
      description: 'Old State',
      app_type: 'ContextExternalTool',
    }

    render(<EditExternalToolButton {...defaultProps} tool={tool} canEdit={true} />)
    const editButton = screen.getByRole('menuitem', {name: /edit.*app/i})
    await userEvent.click(editButton)

    expect(store.fetchWithDetails).toHaveBeenCalledWith(tool)
  })
})
