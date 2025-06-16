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
import ModuleHeaderStudent, {ModuleHeaderStudentProps} from '../ModuleHeaderStudent'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      gcTime: 0,
    },
  },
})

const setUp = (props: ModuleHeaderStudentProps) => {
  return render(
    <QueryClientProvider client={queryClient}>
      <ModuleHeaderStudent {...props} />
    </QueryClientProvider>,
  )
}

const buildDefaultProps = (overrides = {}) => {
  const defaultProps: ModuleHeaderStudentProps = {
    id: '1',
    name: 'Test Module',
    expanded: true,
    onToggleExpand: jest.fn(),
    progression: {
      id: '1',
      _id: '1',
      workflowState: 'unlocked',
      requirementsMet: [],
      completed: false,
      locked: false,
      unlocked: true,
      started: false,
    },
    completionRequirements: [],
    requirementCount: 0,
  }

  return {...defaultProps, ...overrides}
}

describe('ModuleHeaderStudent', () => {
  it('renders properly without progression', () => {
    const {container} = setUp(buildDefaultProps({progression: undefined}))
    expect(container).not.toBeEmptyDOMElement()
  })

  it('renders a module header', () => {
    const {container} = setUp(buildDefaultProps())
    expect(container).not.toBeEmptyDOMElement()
  })

  it('renders locked module icon when progression is locked and no completion requirements exist', () => {
    const progression = {
      id: '1',
      _id: '1',
      workflowState: 'locked',
      requirementsMet: [],
      completed: false,
      locked: true,
      unlocked: false,
      started: false,
    }
    const {getByTestId} = setUp(buildDefaultProps({progression, completionRequirements: []}))
    expect(getByTestId('module-header-status-icon-lock')).toBeInTheDocument()
  })

  describe('prerequisites', () => {
    it('renders prerequisites when one exists', () => {
      const {getByText} = setUp(buildDefaultProps({prerequisites: [{name: 'Test Prerequisite'}]}))
      expect(getByText('Prerequisite: Test Prerequisite')).toBeInTheDocument()
    })

    it('renders prerequisites when multiple exist', () => {
      const {getByText} = setUp(
        buildDefaultProps({
          prerequisites: [{name: 'Test Prerequisite 1'}, {name: 'Test Prerequisite 2'}],
        }),
      )
      expect(
        getByText('Prerequisites: Test Prerequisite 1, Test Prerequisite 2'),
      ).toBeInTheDocument()
    })

    it('does not render prerequisites when none exist', () => {
      const container = setUp(buildDefaultProps({prerequisites: []}))
      expect(container.queryByTestId('module-header-prerequisites')).toBeNull()
    })
  })
})
