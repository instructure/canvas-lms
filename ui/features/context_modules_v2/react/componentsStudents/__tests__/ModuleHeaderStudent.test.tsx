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
import {render, fireEvent} from '@testing-library/react'
import ModuleHeaderStudent, {ModuleHeaderStudentProps} from '../ModuleHeaderStudent'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import {MODULES} from '../../utils/constants'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      gcTime: 0,
    },
  },
})

const setUp = (props: ModuleHeaderStudentProps, itemCount: number = 10) => {
  // Set up modules data for the useModules hook
  const modulePage = {
    pageInfo: {
      hasNextPage: false,
      endCursor: null,
    },
    modules: [
      {
        _id: props.id,
        moduleItemsTotalCount: itemCount,
      },
    ],
    getModuleItemsTotalCount: (moduleId: string) => (moduleId === props.id ? itemCount : 0),
    isFetching: false,
  }

  const modulesData = {
    pages: [modulePage],
    pageParams: [null],
    getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
    isFetching: false,
  }

  queryClient.setQueryData([MODULES, 'course123'], modulesData)

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
        <ModuleHeaderStudent {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

const buildDefaultProps = (overrides = {}) => {
  const defaultProps: ModuleHeaderStudentProps = {
    id: '1',
    name: 'Test Module',
    expanded: true,
    onToggleExpand: vi.fn(),
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
    unlockAt: null,
    submissionStatistics: undefined,
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

  it('renders ModuleHeaderCompletionRequirement when completionRequirements is not empty', () => {
    const {getByTestId} = setUp(
      buildDefaultProps({
        completionRequirements: [
          {
            id: '1',
            type: 'min_percentage',
            minPercentage: 85,
            completed: true,
          },
        ],
      }),
    )
    expect(getByTestId('module-completion-requirement')).toBeInTheDocument()
  })

  it('renders ModuleHeaderMissingCount when submissionStatistics is not empty', () => {
    const {getByTestId} = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: '',
          missingAssignmentCount: 5,
        },
      }),
    )
    expect(getByTestId('module-header-missing-count')).toBeInTheDocument()
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

  describe('Screen Reader Label is shown correctly', () => {
    it('Module items expanded', () => {
      const {getByTestId} = setUp(buildDefaultProps({expanded: true}))

      const toggleButton = getByTestId('module-header-expand-toggle')
      expect(toggleButton).toHaveAttribute('aria-expanded', 'true')
      expect(toggleButton).toHaveAttribute('aria-label', 'Collapse "Test Module"')
    })

    it('Module items collapsed', () => {
      const {getByTestId} = setUp(buildDefaultProps({expanded: false}))

      const toggleButton = getByTestId('module-header-expand-toggle')
      expect(toggleButton).toHaveAttribute('aria-expanded', 'false')
      expect(toggleButton).toHaveAttribute('aria-label', 'Expand "Test Module"')
    })
  })

  describe('Keyboard navigation', () => {
    it('toggles expand when Enter key is pressed', () => {
      const onToggleExpand = vi.fn()
      const {getByTestId} = setUp(buildDefaultProps({expanded: false, onToggleExpand}))

      const toggleButton = getByTestId('module-header-expand-toggle')
      fireEvent.keyDown(toggleButton, {key: 'Enter', code: 'Enter'})

      expect(onToggleExpand).toHaveBeenCalledWith('1')
      expect(onToggleExpand).toHaveBeenCalledTimes(1)
    })

    it('toggles expand when Space key is pressed', () => {
      const onToggleExpand = vi.fn()
      const {getByTestId} = setUp(buildDefaultProps({expanded: false, onToggleExpand}))

      const toggleButton = getByTestId('module-header-expand-toggle')
      fireEvent.keyDown(toggleButton, {key: ' ', code: 'Space'})

      expect(onToggleExpand).toHaveBeenCalledWith('1')
      expect(onToggleExpand).toHaveBeenCalledTimes(1)
    })

    it('does not toggle expand when other keys are pressed', () => {
      const onToggleExpand = vi.fn()
      const {getByTestId} = setUp(buildDefaultProps({expanded: false, onToggleExpand}))

      const toggleButton = getByTestId('module-header-expand-toggle')
      fireEvent.keyDown(toggleButton, {key: 'a', code: 'KeyA'})
      fireEvent.keyDown(toggleButton, {key: 'Escape', code: 'Escape'})
      fireEvent.keyDown(toggleButton, {key: 'Tab', code: 'Tab'})

      expect(onToggleExpand).not.toHaveBeenCalled()
    })
  })
})
