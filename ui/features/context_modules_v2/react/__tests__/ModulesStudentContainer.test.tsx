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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import ModulesStudentContainer from '../ModulesStudentContainer'
import {ContextModuleProvider} from '../hooks/useModuleContext'

// TypeScript interfaces for better type safety
interface ENVObserverOptions {
  OBSERVED_USERS_LIST: Array<{id: string; name: string; avatar_url?: string | null}>
  CAN_ADD_OBSERVEE: boolean
}

interface ENVConfig {
  current_user?: {id: string; name: string}
  current_user_roles?: string[]
  OBSERVER_OPTIONS?: ENVObserverOptions
}

// MSW server for mocking GraphQL requests
const server = setupServer(
  // Mock GetModulesStudentQuery to return empty modules
  graphql.query('GetModulesStudentQuery', () => {
    return HttpResponse.json({
      data: {
        course: {
          modules: {
            nodes: [],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
        },
      },
    })
  }),
  // Mock GetCourseStudentQuery to return minimal course data
  graphql.query('GetCourseStudentQuery', () => {
    return HttpResponse.json({
      data: {
        course: {
          id: '1',
          name: 'Test Course',
        },
      },
    })
  }),
)

// Context module default props
const contextModuleDefaultProps = {
  courseId: '1',
  isMasterCourse: false,
  isChildCourse: false,
  permissions: {
    readAsAdmin: false,
    canAdd: false,
    canEdit: false,
    canDelete: false,
    canViewUnpublished: false,
    canDirectShare: false,
  },
  NEW_QUIZZES_ENABLED: false,
  NEW_QUIZZES_BY_DEFAULT: false,
  DEFAULT_POST_TO_SIS: false,
  teacherViewEnabled: false,
  studentViewEnabled: false,
  restrictQuantitativeData: false,
  moduleMenuModalTools: [],
  moduleGroupMenuTools: [],
  moduleMenuTools: [],
  moduleIndexMenuModalTools: [],
}

describe('ModulesStudentContainer', () => {
  const originalEnv = (window as any).ENV
  let queryClient: QueryClient

  // Build default ENV configuration with overrides pattern
  const buildDefaultENV = (overrides: ENVConfig = {}): ENVConfig => ({
    current_user: {id: '1', name: 'Test User'},
    current_user_roles: ['observer'],
    ...overrides,
  })

  // Setup function for consistent rendering with providers
  const setup = async (envOverrides: ENVConfig = {}) => {
    ;(window as any).ENV = buildDefaultENV(envOverrides)
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const result = render(
      <QueryClientProvider client={queryClient}>
        <ContextModuleProvider {...contextModuleDefaultProps}>
          <ModulesStudentContainer />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    // Wait for initial loading to complete
    await screen.findByText('No modules found')
    return result
  }

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    server.resetHandlers()
  })

  afterEach(() => {
    queryClient?.clear()
    ;(window as any).ENV = originalEnv
  })

  afterAll(() => {
    server.close()
  })

  describe('Component Structure', () => {
    it('always renders the main container and differentiated modules mount point', async () => {
      await setup({
        OBSERVER_OPTIONS: {
          OBSERVED_USERS_LIST: [],
          CAN_ADD_OBSERVEE: false,
        },
      })

      expect(screen.getByTestId('modules-rewrite-student-container')).toBeInTheDocument()
      expect(screen.getByText('No modules found')).toBeInTheDocument()
      expect(document.getElementById('differentiated-modules-mount-point')).toBeInTheDocument()
    })

    it('renders only module content without observer dropdown', async () => {
      await setup({
        OBSERVER_OPTIONS: {
          OBSERVED_USERS_LIST: [{id: '2', name: 'Student 1', avatar_url: null}],
          CAN_ADD_OBSERVEE: false,
        },
      })

      const container = screen.getByTestId('modules-rewrite-student-container')
      const children = Array.from(container.children)

      // Should only have module list and mount point, no observer dropdown in React
      expect(children).toHaveLength(2)
      expect(children[0]).toContainElement(screen.getByText('No modules found'))
      expect(children[1]).toBe(document.getElementById('differentiated-modules-mount-point'))

      // Observer dropdown should not be rendered in the React component
      expect(screen.queryByText(/You are observing/)).not.toBeInTheDocument()
      expect(screen.queryByText('Select a student to view')).not.toBeInTheDocument()
    })
  })

  describe('Observer Dropdown Handling', () => {
    it('does not render observer dropdown in React component regardless of observer status', async () => {
      await setup({
        OBSERVER_OPTIONS: {
          OBSERVED_USERS_LIST: [{id: '2', name: 'Student 1', avatar_url: null}],
          CAN_ADD_OBSERVEE: true,
        },
      })

      // Observer dropdown should never be in the React component - handled by ERB mounting
      expect(screen.getByTestId('modules-rewrite-student-container')).toBeInTheDocument()
      expect(screen.queryByText(/You are observing/)).not.toBeInTheDocument()
      expect(screen.queryByText('Select a student to view')).not.toBeInTheDocument()
      expect(screen.getByText('No modules found')).toBeInTheDocument()
    })

    it('handles missing OBSERVER_OPTIONS gracefully', async () => {
      await setup() // No OBSERVER_OPTIONS provided

      expect(screen.getByTestId('modules-rewrite-student-container')).toBeInTheDocument()
      expect(screen.queryByText(/You are observing/)).not.toBeInTheDocument()
      expect(screen.queryByText('Select a student to view')).not.toBeInTheDocument()
      expect(screen.getByText('No modules found')).toBeInTheDocument()
    })
  })

  describe('Edge Cases', () => {
    it('handles malformed ENV data gracefully', async () => {
      ;(window as any).ENV = {}
      queryClient = new QueryClient({
        defaultOptions: {
          queries: {
            retry: false,
          },
        },
      })

      render(
        <QueryClientProvider client={queryClient}>
          <ContextModuleProvider {...contextModuleDefaultProps}>
            <ModulesStudentContainer />
          </ContextModuleProvider>
        </QueryClientProvider>,
      )

      await screen.findByText('No modules found')

      expect(screen.getByTestId('modules-rewrite-student-container')).toBeInTheDocument()
      expect(screen.queryByText(/You are observing/)).not.toBeInTheDocument()
      expect(screen.queryByText('Select a student to view')).not.toBeInTheDocument()
      expect(screen.getByText('No modules found')).toBeInTheDocument()
    })

    it('maintains semantic structure', async () => {
      await setup({
        OBSERVER_OPTIONS: {
          OBSERVED_USERS_LIST: [{id: '2', name: 'Student 1', avatar_url: null}],
          CAN_ADD_OBSERVEE: false,
        },
      })

      const container = screen.getByTestId('modules-rewrite-student-container')
      expect(container).toBeInTheDocument()
      expect(container.tagName).toBe('DIV')
    })
  })
})
