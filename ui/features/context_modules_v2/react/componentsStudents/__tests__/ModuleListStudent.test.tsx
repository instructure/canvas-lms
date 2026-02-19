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
import {render, screen, waitFor} from '@testing-library/react'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModulesListStudent from '../ModuleListStudent'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fakeEnv from '@canvas/test-utils/fakeENV'

type ComponentProps = object

const setUp = (props: ComponentProps = {}, courseId = 'test-course-id') => {
  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextProps}>
        <ModulesListStudent {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

const buildDefaultProps = (overrides: Partial<ComponentProps> = {}): ComponentProps => ({
  ...overrides,
})

const server = setupServer()

describe('ModulesListStudent', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    fakeEnv.teardown()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    fakeEnv.setup({
      TIMEZONE: 'UTC',
    })

    // Default mocks to prevent warnings
    server.use(
      graphql.query('GetCourseStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              name: 'Test Course',
              submissionStatistics: {
                missingSubmissionsCount: 0,
                submissionsDueThisWeekCount: 0,
              },
              settings: {
                showStudentOnlyModuleId: null,
              },
            },
          },
        })
      }),
      graphql.query('GetModuleItemsStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              moduleItems: [],
            },
          },
        })
      }),
    )
  })

  it('shows a loading spinner when loading and no data', () => {
    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return new Promise(() => {})
      }),
    )

    setUp(buildDefaultProps())
    expect(screen.getByText('Loading modules')).toBeInTheDocument()
  })

  it('shows error message if error is present', async () => {
    const courseId = 'test-course-id'
    const errorMsg = 'Failed to load modules'

    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    setUp(buildDefaultProps(), courseId)

    await waitFor(() => {
      expect(screen.getByText('Error loading modules')).toBeInTheDocument()
    })
  })

  it('shows no modules message when modules array is empty', async () => {
    const courseId = 'test-course-id'

    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              modulesConnection: {
                edges: [],
                pageInfo: {hasNextPage: false, endCursor: null},
              },
            },
          },
        })
      }),
    )

    setUp(buildDefaultProps(), courseId)
    await waitFor(() => {
      expect(screen.getByText('No modules found')).toBeInTheDocument()
    })
  })

  it('renders a module if one exists', async () => {
    const courseId = 'test-course-id'
    const moduleId = 'module-1'

    server.use(
      graphql.query('GetModulesStudentQuery', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              modulesConnection: {
                edges: [
                  {
                    node: {
                      _id: moduleId,
                      name: 'Intro Module',
                      completionRequirements: [],
                      prerequisites: [
                        {id: 'prereq-1', name: 'Prerequisite Module', type: 'context_module'},
                      ],
                      requireSequentialProgress: false,
                      progression: {collapsed: false},
                      requirementCount: 0,
                      unlockAt: null,
                      submissionStatistics: null,
                    },
                  },
                ],
                pageInfo: {hasNextPage: false, endCursor: null},
              },
            },
          },
        })
      }),
    )

    setUp(buildDefaultProps(), courseId)
    await waitFor(() => {
      expect(screen.getByText('Intro Module')).toBeInTheDocument()
    })
  })
})
