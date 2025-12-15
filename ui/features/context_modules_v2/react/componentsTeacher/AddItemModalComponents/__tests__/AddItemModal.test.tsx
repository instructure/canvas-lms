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

import {render, screen, waitFor, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../../hooks/useModuleContext'
import AddItemModal from '../AddItemModal'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'

const server = setupServer(
  graphql.query('GetAssignmentsQuery', () => {
    return HttpResponse.json({
      data: {
        course: {
          assignmentsConnection: {
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
  graphql.query('GetAssignmentGroupsQuery', () => {
    return HttpResponse.json({
      data: {
        course: {
          assignmentGroupsConnection: {
            edges: [],
          },
        },
      },
    })
  }),
)

const renderWithProviders = (props: Partial<React.ComponentProps<typeof AddItemModal>> = {}) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <ContextModuleProvider {...contextModuleDefaultProps}>
        <AddItemModal
          isOpen={true}
          onRequestClose={vi.fn()}
          moduleName="Test Module"
          moduleId="1"
          {...props}
        />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('AddItemModal', () => {
  beforeAll(() => server.listen())
  beforeEach(() => {
    // Create live region element required by Alert component
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })
  afterEach(() => {
    server.resetHandlers()
    // Clean up live region element
    const liveRegion = document.getElementById('flash_screenreader_holder')
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
  })
  afterAll(() => server.close())

  describe('Title validation', () => {
    it('shows error if name is empty in Create tab and prevents submit', async () => {
      renderWithProviders()

      await userEvent.click(screen.getByRole('tab', {name: /create item/i}))
      const nameInput = await screen.findByLabelText(/name/i)
      await userEvent.clear(nameInput)
      await userEvent.click(screen.getByTestId('submit-button'))
      const createPanel = await screen.findByRole('tabpanel', {name: /create item/i})
      expect(
        await within(createPanel).findByText('Assignment name is required', {exact: true}),
      ).toBeInTheDocument()
    })

    it('removes error when a valid name is entered', async () => {
      renderWithProviders()

      await userEvent.click(screen.getByRole('tab', {name: /create item/i}))
      const nameInput = await screen.findByLabelText(/name/i)
      await userEvent.clear(nameInput)
      await userEvent.click(screen.getByTestId('submit-button'))
      const createPanel = await screen.findByRole('tabpanel', {name: /create item/i})
      expect(
        await within(createPanel).findByText('Assignment name is required', {exact: true}),
      ).toBeInTheDocument()

      await userEvent.type(nameInput, 'Valid Name')
      await waitFor(() => {
        expect(
          within(createPanel).queryByText('Assignment name is required', {exact: true}),
        ).not.toBeInTheDocument()
      })
    })
  })

  describe('AsyncSelect Integration', () => {
    it('renders AsyncSelect for content selection', async () => {
      server.use(
        graphql.query('GetAssignmentsQuery', () => {
          return HttpResponse.json({
            data: {
              course: {
                assignmentsConnection: {
                  nodes: [{_id: '1', name: 'Test Assignment'}],
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

      renderWithProviders()

      expect(screen.getByTestId('add-item-content-select')).toBeInTheDocument()
    })

    it('shows validation error when no item is selected on Add Item tab', async () => {
      server.use(
        graphql.query('GetAssignmentsQuery', () => {
          return HttpResponse.json({
            data: {
              course: {
                assignmentsConnection: {
                  nodes: [{_id: '1', name: 'Test Assignment'}],
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

      renderWithProviders()

      const select = screen.getByTestId('add-item-content-select')
      expect(select).toHaveAttribute('required')

      const submitButton = screen.getByTestId('submit-button')
      await userEvent.click(submitButton)
      expect(screen.getByTestId('add-item-modal')).toBeInTheDocument()
    })

    it('allows form submission when item is selected', async () => {
      const mockOnClose = vi.fn()

      server.use(
        graphql.query('GetAssignmentsQuery', () => {
          return HttpResponse.json({
            data: {
              course: {
                assignmentsConnection: {
                  nodes: [{_id: '1', name: 'Test Assignment'}],
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

      renderWithProviders({onRequestClose: mockOnClose})

      const select = screen.getByTestId('add-item-content-select')
      await userEvent.type(select, 'Test')

      const option = await screen.findByText('Test Assignment')
      expect(option).toBeInTheDocument()

      await userEvent.click(option)
      await userEvent.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(screen.queryByText('Assignment is required')).not.toBeInTheDocument()
      })
    })

    it('shows loading state while fetching assignments', async () => {
      let resolveQuery: (value: any) => void
      const queryPromise = new Promise(resolve => {
        resolveQuery = resolve
      })

      server.use(
        graphql.query('GetAssignmentsQuery', async () => {
          await queryPromise
          return HttpResponse.json({
            data: {
              course: {
                assignmentsConnection: {
                  nodes: [{_id: '1', name: 'Test Assignment'}],
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

      renderWithProviders()

      const select = screen.getByTestId('add-item-content-select')
      expect(select).toBeInTheDocument()

      await userEvent.type(select, 'Test')

      resolveQuery!(null)

      await waitFor(() => {
        expect(screen.getByText('Test Assignment')).toBeInTheDocument()
      })
    })
  })
})
