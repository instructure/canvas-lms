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
            edges: [],
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
  prerequisites: [],
  completionRequirements: [],
  requirementCount: 0,
  itemCount: 5,
  published: true,
  expanded: true,
  hasActiveOverrides: false,
  setModuleAction: jest.fn(),
  setIsManageModuleContentTrayOpen: jest.fn(),
  setSourceModule: jest.fn(),
  ...overrides,
})

const setUp = (props: ComponentProps, courseId = 'test-course-id') => {
  const queryClient = createQueryClient()

  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextProps}>
        <ModuleHeaderActionPanel {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

beforeAll(() => {
  server.listen({onUnhandledRequest: 'warn'})
})

beforeEach(() => {
  // @ts-expect-error
  window.ENV = {
    TIMEZONE: 'UTC',
  }
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

describe('ModuleHeaderActionPanel', () => {
  it('renders ViewAssignTo when hasActiveOverrides is true', () => {
    const {getByText} = setUp(buildDefaultProps({hasActiveOverrides: true}))
    expect(getByText('View Assign To')).toBeInTheDocument()
  })

  it('does not render ViewAssignTo when hasActiveOverrides is false', () => {
    const {queryByText} = setUp(buildDefaultProps({hasActiveOverrides: false}))
    expect(queryByText('View Assign To')).not.toBeInTheDocument()
  })

  it('does not display prerequisites (moved to ModuleHeader)', () => {
    const prerequisiteProps = buildDefaultProps({
      prerequisites: [
        {id: 'prereq_1', name: 'Prerequisite Module 1', type: 'context_module'},
        {id: 'prereq_2', name: 'Prerequisite Module 2', type: 'context_module'},
      ],
      hasActiveOverrides: false,
    })
    const {queryByText} = setUp(prerequisiteProps)

    expect(queryByText(/Prerequisite/)).not.toBeInTheDocument()
    expect(queryByText('Prerequisite Module 1')).not.toBeInTheDocument()
  })
})
