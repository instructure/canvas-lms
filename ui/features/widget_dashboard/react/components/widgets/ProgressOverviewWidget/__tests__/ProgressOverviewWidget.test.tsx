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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import ProgressOverviewWidget from '../ProgressOverviewWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'

const mockWidget: Widget = {
  id: 'test-progress-overview',
  type: 'progress_overview',
  position: {col: 1, row: 1, relative: 1},
  title: 'Progress overview',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const mockProgressData = [
  {
    course: {
      _id: '1',
      name: 'Environmental Science',
      courseCode: 'ENVS150',
      submissionStatistics: {
        submittedAndGradedCount: 8,
        submittedNotGradedCount: 2,
        missingSubmissionsCount: 1,
        submissionsDueCount: 3,
      },
    },
  },
  {
    course: {
      _id: '2',
      name: 'Calculus II',
      courseCode: 'MATH201',
      submissionStatistics: {
        submittedAndGradedCount: 5,
        submittedNotGradedCount: 1,
        missingSubmissionsCount: 2,
        submissionsDueCount: 4,
      },
    },
  },
]

const mockGqlResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: mockProgressData,
      },
    },
  },
}

const setup = (props: Partial<BaseWidgetProps> = {}, dashboardProps = {}) => {
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
  }

  const defaultProps = buildDefaultProps(props)
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider {...dashboardProps}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>
            <ProgressOverviewWidget {...defaultProps} />
          </WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )

  return {
    ...result,
    cleanup: () => {
      window.ENV = originalEnv
      result.unmount()
    },
  }
}

const server = setupServer(
  graphql.query('GetUserProgressOverview', () => {
    return HttpResponse.json(mockGqlResponse)
  }),
)

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  clearWidgetDashboardCache()
})
afterAll(() => server.close())

describe('ProgressOverviewWidget', () => {
  it('renders widget title', () => {
    const {cleanup} = setup()
    expect(screen.getByText('Progress overview')).toBeInTheDocument()
    cleanup()
  })

  it('renders widget container', () => {
    const {cleanup} = setup()
    expect(screen.getByTestId('widget-test-progress-overview')).toBeInTheDocument()
    cleanup()
  })

  it('displays loading state initially', () => {
    const {cleanup} = setup()
    expect(screen.getByText('Loading progress overview...')).toBeInTheDocument()
    cleanup()
  })

  it('renders courses after loading', async () => {
    const {cleanup} = setup()

    await waitFor(() => {
      expect(screen.getByTestId('course-progress-item-1')).toBeInTheDocument()
      expect(screen.getByTestId('course-progress-item-2')).toBeInTheDocument()
    })

    cleanup()
  })

  it('renders progress bars for each course', async () => {
    const {cleanup} = setup()

    await waitFor(() => {
      expect(screen.getByTestId('progress-bar-1')).toBeInTheDocument()
      expect(screen.getByTestId('progress-bar-2')).toBeInTheDocument()
    })

    cleanup()
  })

  it('displays no courses message when empty', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [],
              },
            },
          },
        })
      }),
    )

    const {cleanup} = setup()

    await waitFor(() => {
      expect(screen.getByTestId('no-courses-message')).toBeInTheDocument()
      expect(screen.getByText('No courses found')).toBeInTheDocument()
    })

    cleanup()
  })

  it('displays error message on failure', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({errors: [{message: 'Failed to fetch'}]}, {status: 500})
      }),
    )

    const {cleanup} = setup()

    await waitFor(() => {
      expect(
        screen.getByText('Failed to load progress overview. Please try again.'),
      ).toBeInTheDocument()
    })

    cleanup()
  })

  it('renders course links correctly', async () => {
    const {cleanup} = setup()

    await waitFor(() => {
      expect(screen.getByTestId('course-link-1')).toBeInTheDocument()
      expect(screen.getByTestId('course-link-2')).toBeInTheDocument()
    })

    expect(screen.getByTestId('course-link-1')).toHaveAttribute('href', '/courses/1')
    expect(screen.getByTestId('course-link-2')).toHaveAttribute('href', '/courses/2')

    cleanup()
  })

  it('filters out courses with null submissionStatistics', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [
                  mockProgressData[0],
                  {
                    course: {
                      _id: '3',
                      name: 'Course Without Stats',
                      courseCode: 'TEST303',
                      submissionStatistics: null,
                    },
                  },
                ],
              },
            },
          },
        })
      }),
    )

    const {cleanup} = setup()

    await waitFor(() => {
      expect(screen.getByTestId('course-progress-item-1')).toBeInTheDocument()
    })

    expect(screen.queryByTestId('course-progress-item-3')).not.toBeInTheDocument()

    cleanup()
  })

  it('supports observer mode', async () => {
    const observedUserId = '456'

    server.use(
      graphql.query('GetUserProgressOverview', ({variables}) => {
        expect(variables.observedUserId).toBe(observedUserId)
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {cleanup} = setup({}, {observedUserId})

    await waitFor(() => {
      expect(screen.getByTestId('course-progress-item-1')).toBeInTheDocument()
    })

    cleanup()
  })
})
