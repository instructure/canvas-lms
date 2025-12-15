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
import {setupServer} from 'msw/node'
import {http, HttpResponse, graphql} from 'msw'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleHeaderActionPanel from '../ModuleHeaderActionPanel'

type ComponentProps = React.ComponentProps<typeof ModuleHeaderActionPanel>

const server = setupServer(
  graphql.query('GetModulesQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          modulesConnection: {
            edges: [
              {
                node: {
                  _id: 'mod_1',
                  name: 'Module 1',
                  moduleItemsTotalCount: 15,
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
        },
      },
    })
  }),
  graphql.query('GetModuleItemsQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          moduleItems: [],
        },
      },
    })
  }),
  graphql.query('GetCourseFolders', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          id: 'test-course-id',
          name: 'Test Course',
          foldersConnection: {
            nodes: [],
          },
        },
      },
    })
  }),
  http.get('/api/v1/courses/test-course-id/folders/root', () => {
    return HttpResponse.json({
      id: 'root',
      name: 'course files',
      full_name: 'course files',
      folders_url: '/api/v1/folders/root/folders',
      files_url: '/api/v1/folders/root/files',
    })
  }),
)

const createQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

const buildDefaultProps = (overrides: Partial<ComponentProps> = {}): ComponentProps => ({
  id: 'mod_1',
  name: 'Module 1',
  completionRequirements: [],
  requirementCount: 0,
  published: true,
  expanded: true,
  hasActiveOverrides: false,
  setModuleAction: vi.fn(),
  setIsManageModuleContentTrayOpen: vi.fn(),
  setSourceModule: vi.fn(),
  ...overrides,
})

const defaultPermissions = {
  canAdd: true,
  canEdit: true,
  canDelete: true,
  canView: true,
  canViewUnpublished: true,
  canDirectShare: true,
  readAsAdmin: true,
  canManageSpeedGrader: true,
}

const setUp = (
  props: ComponentProps,
  courseId = 'test-course-id',
  itemCount = 15,
  contextOverrides: Partial<typeof contextModuleDefaultProps> = {},
) => {
  const queryClient = createQueryClient()

  // Mock the modules data in the query client
  queryClient.setQueryData(['modules', courseId], {
    pages: [
      {
        modules: [
          {
            _id: 'mod_1',
            id: 'mod_1',
            name: 'Module 1',
            moduleItemsTotalCount: itemCount,
          },
        ],
        pageInfo: {
          hasNextPage: false,
          endCursor: null,
        },
      },
    ],
    pageParams: [undefined],
  })

  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
    modulesArePaginated: true,
    pageSize: 10,
    ...contextOverrides,
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextProps}>
        <ModuleHeaderActionPanel {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleHeaderActionPanel', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())
  it('renders ViewAssignTo when hasActiveOverrides is true', () => {
    const {getByText} = setUp(buildDefaultProps({hasActiveOverrides: true}))
    expect(getByText('View Assign To')).toBeInTheDocument()
  })

  it('does not render ViewAssignTo when hasActiveOverrides is false', () => {
    const {queryByText} = setUp(buildDefaultProps({hasActiveOverrides: false}))
    expect(queryByText('View Assign To')).not.toBeInTheDocument()
  })

  it('does not render ViewAssignTo when canEdit is false', () => {
    const {queryByText} = setUp(buildDefaultProps(), 'test-course-id', 15, {
      permissions: {
        ...defaultPermissions,
        canEdit: false,
      },
    })
    expect(queryByText('View Assign To')).not.toBeInTheDocument()
  })

  it('does not render Add Module Item button when canAdd is false', () => {
    const {queryByTestId} = setUp(buildDefaultProps(), 'test-course-id', 15, {
      permissions: {
        ...defaultPermissions,
        canAdd: false,
      },
    })
    expect(queryByTestId('add-item-button')).not.toBeInTheDocument()
  })

  it('does not render the publish button when canEdit is false', () => {
    const {queryByTestId} = setUp(buildDefaultProps(), 'test-course-id', 15, {
      permissions: {
        ...defaultPermissions,
        canEdit: false,
      },
    })
    expect(queryByTestId('module-publish-button')).not.toBeInTheDocument()
  })

  it('does not show Show All button when module is not expanded', () => {
    const {queryByTestId} = setUp(buildDefaultProps({expanded: false}))
    expect(queryByTestId('show-all-toggle')).not.toBeInTheDocument()
  })

  it('shows Show All button with item count when expanded', () => {
    setUp(buildDefaultProps({expanded: true}))

    const button = screen.getByTestId('show-all-toggle')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('Show All (15)')
  })

  it('calls onToggleShowAll when Show All button is clicked', async () => {
    const user = userEvent.setup()
    const mockToggleShowAll = vi.fn()

    setUp(
      buildDefaultProps({
        expanded: true,
        onToggleShowAll: mockToggleShowAll,
      }),
    )

    const button = screen.getByTestId('show-all-toggle')
    await user.click(button)

    expect(mockToggleShowAll).toHaveBeenCalledWith('mod_1')
  })

  it('shows Show Less text when showAll is true', () => {
    setUp(
      buildDefaultProps({
        expanded: true,
        showAll: true,
      }),
    )

    const button = screen.getByTestId('show-all-toggle')
    expect(button).toHaveTextContent('Show Less')
  })

  it('does not show Show All button when pagination is disabled', () => {
    const {queryByTestId} = setUp(buildDefaultProps({expanded: true}), 'test-course-id', 15, {
      modulesArePaginated: false,
    })
    expect(queryByTestId('show-all-toggle')).not.toBeInTheDocument()
  })

  it('does not show Show All button when total count is less than page size', async () => {
    const {queryByTestId} = setUp(buildDefaultProps({expanded: true}), 'test-course-id', 5)
    expect(queryByTestId('show-all-toggle')).not.toBeInTheDocument()
  })

  it('shows Show All button with different page size', () => {
    // Use itemCount of 15 which exceeds page size of 5
    setUp(buildDefaultProps({expanded: true}), 'test-course-id', 15, {pageSize: 5})

    const button = screen.getByTestId('show-all-toggle')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('Show All (15)')
  })

  it('does not show Show All button when count equals page size', () => {
    // Test edge case where count equals page size exactly
    const {queryByTestId} = setUp(buildDefaultProps({expanded: true}), 'test-course-id', 10)
    expect(queryByTestId('show-all-toggle')).not.toBeInTheDocument()
  })
})
