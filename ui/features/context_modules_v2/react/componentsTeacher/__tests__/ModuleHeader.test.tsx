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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleHeader from '../ModuleHeader'
import {PAGE_SIZE, MODULE_ITEMS, MODULES} from '../../utils/constants'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/context-modules/react/publishing/publishingContext', async () => {
  const actual = await vi.importActual('@canvas/context-modules/react/publishing/publishingContext')
  return {
    ...actual,
    usePublishing: vi.fn(() => ({
      publishingInProgress: false,
    })),
  }
})

const server = setupServer(
  graphql.query('GetModuleItemsQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          moduleItemsConnection: {
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

interface ModuleHeaderProps {
  id: string
  name: string
  expanded: boolean
  onToggleExpand: (id: string) => void
  published: boolean
  prerequisites?: Array<{id: string; name: string; type: string}>
  completionRequirements?: Array<any>
  requirementCount: number
  unlockAt: string | null
  dragHandleProps?: any
  hasActiveOverrides: boolean
  itemCount: number
  setModuleAction?: React.Dispatch<React.SetStateAction<any>>
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const buildDefaultProps = (overrides: Partial<ModuleHeaderProps> = {}): ModuleHeaderProps => {
  const id = overrides.id ?? 'mod_1'

  return {
    id,
    name: 'Test Module',
    expanded: false,
    onToggleExpand: vi.fn(),
    published: true,
    prerequisites: [],
    completionRequirements: [],
    requirementCount: 0,
    unlockAt: null,
    hasActiveOverrides: false,
    itemCount: 5,
    ...overrides,
  }
}

const setUp = (props: ModuleHeaderProps, courseId = 'test-course-id') => {
  const queryClient = createQueryClient()

  // Set up query data for modules
  queryClient.setQueryData([MODULES, courseId], {
    pages: [
      {
        modules: [
          {
            id: props.id,
            name: props.name,
            position: 1,
            published: props.published,
            moduleItems: [],
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

  // Set up query data for module items
  queryClient.setQueryData([MODULE_ITEMS, props.id, null, PAGE_SIZE], {
    moduleItems: [],
  })

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
        <ModuleHeader {...props} />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleHeader', () => {
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
  })

  it('renders module name', () => {
    const {getByText} = setUp(buildDefaultProps())
    expect(getByText('Test Module')).toBeInTheDocument()
  })

  it('displays prerequisites when present', () => {
    const prerequisites = [
      {id: 'prereq_1', name: 'Prerequisite Module 1', type: 'context_module'},
      {id: 'prereq_2', name: 'Prerequisite Module 2', type: 'context_module'},
    ]
    const {getByTestId} = setUp(buildDefaultProps({prerequisites}))

    const prerequisiteText = getByTestId('module-header-prerequisites')
    expect(prerequisiteText).toBeInTheDocument()
    expect(prerequisiteText).toHaveTextContent(
      'Prerequisites: Prerequisite Module 1, Prerequisite Module 2',
    )
  })

  it('displays single prerequisite with correct label', () => {
    const prerequisites = [{id: 'prereq_1', name: 'Single Prerequisite', type: 'context_module'}]
    const {getByTestId} = setUp(buildDefaultProps({prerequisites}))

    const prerequisiteText = getByTestId('module-header-prerequisites')
    expect(prerequisiteText).toHaveTextContent('Prerequisite: Single Prerequisite')
  })

  it('does not display prerequisites when none exist', () => {
    const {queryByTestId} = setUp(buildDefaultProps({prerequisites: []}))
    expect(queryByTestId('module-header-prerequisites')).not.toBeInTheDocument()
  })
})
