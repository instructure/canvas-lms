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
import {render, screen, fireEvent} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import ViewAssignTo, {ViewAssignToProps} from '../ViewAssignTo'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import {MODULES} from '../../../utils/constants'

const server = setupServer(
  graphql.query('GetModulesQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          modulesConnection: {
            edges: [
              {
                cursor: 'cursor',
                node: {
                  id: '456',
                  _id: '456',
                  name: 'Test Module',
                  position: 1,
                  published: true,
                  unlockAt: null,
                  requirementCount: 0,
                  requireSequentialProgress: false,
                  hasActiveOverrides: false,
                  prerequisites: [],
                  state: 'active',
                  itemsConnection: {
                    edges: [],
                  },
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
          moduleItemsConnection: {
            edges: [],
          },
        },
      },
    })
  }),
)

// Setup DOM elements that the component may need
beforeEach(() => {
  // Create container for any dynamic content
  const container = document.createElement('div')
  container.id = 'context_modules_sortable_container'
  document.body.appendChild(container)

  // Add a mock button for focus management
  const addButton = document.createElement('button')
  addButton.className = 'add-module-button'
  document.body.appendChild(addButton)
})

afterEach(() => {
  // Clean up DOM elements
  const container = document.getElementById('context_modules_sortable_container')
  if (container) {
    container.remove()
  }
  const addButton = document.querySelector('.add-module-button')
  if (addButton) {
    addButton.remove()
  }
})

describe('ViewAssignTo', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })
  afterAll(() => server.close())

  const buildDefaultProps = (overrides: Partial<ViewAssignToProps> = {}): ViewAssignToProps => ({
    moduleId: '456',
    moduleName: 'Test Module',
    expanded: true,
    isMenuOpen: true,
    prerequisites: [],
    ...overrides,
  })

  const setUp = (props: ViewAssignToProps = buildDefaultProps()) => {
    const contextValue = {
      ...contextModuleDefaultProps,
      courseId: '123',
    }

    return render(
      <MockedQueryClientProvider client={queryClient}>
        <ContextModuleProvider {...contextValue}>
          <ViewAssignTo {...props} />
        </ContextModuleProvider>
      </MockedQueryClientProvider>,
    )
  }

  it('renders the link text', () => {
    setUp()

    expect(screen.getByText('View Assign To')).toBeInTheDocument()
  })

  it('renders a clickable link', () => {
    setUp()

    const link = screen.getByRole('button', {name: 'View Assign To'})
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('type', 'button')
  })

  it('can be clicked without errors', () => {
    setUp()

    const link = screen.getByRole('button', {name: 'View Assign To'})

    // This should not throw an error when clicked
    expect(() => {
      fireEvent.click(link)
    }).not.toThrow()
  })

  it('disables the link when module items are loading', () => {
    // Don't set module items data to simulate loading state
    queryClient.setQueryData([MODULES, '123'], {
      pages: [
        {
          modules: [
            {
              _id: '456',
              name: 'Test Module',
              items_count: 0,
              state: 'active',
              position: 1,
              unlock_at: null,
              require_sequential_progress: false,
              prerequisite_module_ids: [],
              items_url: '/api/v1/courses/123/modules/456/items',
              items: [],
            },
          ],
          pageInfo: {
            hasNextPage: false,
            endCursor: null,
          },
        },
      ],
      pageParams: [],
    })

    setUp()

    const link = screen.getByRole('button', {name: 'View Assign To'})
    expect(link).toHaveAttribute('aria-disabled', 'true')
  })
})
