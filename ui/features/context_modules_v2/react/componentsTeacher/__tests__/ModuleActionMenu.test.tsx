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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {queryClient} from '@canvas/query'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleActionMenu from '../ModuleActionMenu'
import {MODULE_ITEMS, MODULE_ITEM_TITLES, MODULES} from '../../utils/constants'

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
            edges: [
              {
                node: {
                  _id: 'mod_1',
                  id: 'mod_1',
                  name: 'Test Module',
                  moduleItemsTotalCount: 2,
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
)
import {
  handleDelete,
  handleDuplicate,
  handleSendTo,
  handleCopyTo,
} from '../../handlers/moduleActionHandlers'
import {handleOpeningModuleUpdateTray} from '../../handlers/modulePageActionHandlers'
import '../../handlers/modulePageCommandEventHandlers'

vi.mock('../../handlers/moduleActionHandlers')
vi.mock('../../handlers/modulePageActionHandlers', async () => ({
  ...await vi.importActual('../../handlers/modulePageActionHandlers'),
  handleOpeningModuleUpdateTray: vi.fn(),
}))

const setIsManagementContentTrayOpenMock = vi.fn()

// External tool data to be provided through context
const mockExternalTools = {
  moduleGroupMenuTools: [
    {
      id: 'tool1',
      title: 'External Tool 1',
      base_url: 'https://example.com/tool1',
    },
  ],
  moduleMenuModalTools: [
    {
      definition_type: 'ContextExternalTool',
      definition_id: 'tool2',
      name: 'External Tool 2',
      placements: {
        module_menu_modal: {
          url: 'https://example.com/tool2',
          title: 'External Tool 2',
        },
      },
    },
  ],
  moduleMenuTools: [
    {
      id: 'tool3',
      title: 'External Tool 3',
      base_url: 'https://example.com/tool3',
    },
  ],
  moduleIndexMenuModalTools: [],
}

const setUp = (permissions = {}, courseId = 'test-course-id', moduleId = 'test-module-id') => {
  // Set up query data for modules
  queryClient.setQueryData([MODULES, courseId], {
    pages: [
      {
        modules: [
          {
            _id: moduleId,
            id: moduleId,
            name: 'Test Module 1',
            position: 1,
            published: true,
            moduleItems: [],
          },
          {
            _id: 'test-module-id-2',
            id: 'test-module-id-2',
            name: 'Test Module 2',
            position: 2,
            published: true,
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
  queryClient.setQueryData([MODULE_ITEMS, moduleId, null], {
    moduleItems: [
      {
        _id: '1',
        id: '1',
        title: 'Test Item',
        content: {
          canDuplicate: true,
        },
      },
    ],
  })

  queryClient.setQueryData([MODULE_ITEM_TITLES, moduleId], {
    legacyNode: {
      moduleItemsConnection: {
        edges: [
          {
            node: {
              _id: '1',
              id: '1',
              title: 'Test Item',
            },
          },
        ],
      },
    },
  })

  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    permissions: {
      ...contextModuleDefaultProps.permissions,
      ...permissions,
    },
    ...mockExternalTools,
  }

  return renderMenu({
    moduleId,
    contextProps,
    queryClientOverride: queryClient,
  })
}

const renderMenu = ({
  moduleId = 'test-module-id',
  contextProps = {},
  queryClientOverride = null,
}: {
  moduleId?: string
  contextProps?: any
  queryClientOverride?: QueryClient | null
} = {}) => {
  const client = queryClientOverride || queryClient
  return render(
    <QueryClientProvider client={client}>
      <ContextModuleProvider {...contextProps}>
        <ModuleActionMenu
          expanded={true}
          isMenuOpen={false}
          setIsMenuOpen={() => {}}
          id={moduleId}
          name="Test Module"
          setIsDirectShareOpen={() => {}}
          setIsDirectShareCourseOpen={() => {}}
          setModuleAction={() => {}}
          setIsManageModuleContentTrayOpen={setIsManagementContentTrayOpenMock}
          setSourceModule={() => {}}
        />
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleActionMenu', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })
  afterAll(() => server.close())
  describe('rendering', () => {
    it('renders the menu trigger button', () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      expect(menuButton).toBeInTheDocument()
      expect(menuButton).toHaveAttribute('data-testid', 'module-action-menu_test-module-id')
    })

    it('renders all menu items when user has all permissions', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Check that all menu items are rendered
      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument()
      })
      expect(screen.getByText('Move Contents...')).toBeInTheDocument()
      expect(screen.getByText('Move Module...')).toBeInTheDocument()
      expect(screen.getByText('Assign To...')).toBeInTheDocument()
      expect(screen.getByText('Delete')).toBeInTheDocument()
      expect(screen.getByText('Duplicate')).toBeInTheDocument()
      expect(screen.getByText('Send To...')).toBeInTheDocument()
      expect(screen.getByText('Copy To...')).toBeInTheDocument()
    })

    it('renders external tool menu items', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Check that external tool menu items are rendered
      await waitFor(() => {
        expect(screen.getByText('External Tool 1')).toBeInTheDocument()
      })
      expect(screen.getByText('External Tool 2')).toBeInTheDocument()
      expect(screen.getByText('External Tool 3')).toBeInTheDocument()
    })

    it('only renders edit menu items when user can only edit', async () => {
      setUp({
        canEdit: true,
        canDelete: false,
        canAdd: false,
        canDirectShare: false,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Should show edit-related items
      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument()
      })
      expect(screen.getByText('Move Contents...')).toBeInTheDocument()
      expect(screen.getByText('Move Module...')).toBeInTheDocument()
      expect(screen.getByText('Assign To...')).toBeInTheDocument()

      // Should not show delete, duplicate, or share items
      expect(screen.queryByText('Delete')).not.toBeInTheDocument()
      expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
      expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
    })

    it('only renders delete menu item when user can only delete', async () => {
      setUp({
        canEdit: false,
        canDelete: true,
        canAdd: false,
        canDirectShare: false,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Should show delete item
      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })

      // Should not show other items
      expect(screen.queryByText('Edit')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
      expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
      expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
    })

    it('only renders duplicate menu item when user can add and module is expanded', async () => {
      setUp({
        canEdit: false,
        canDelete: false,
        canAdd: true,
        canDirectShare: false,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Should show duplicate item (since module is expanded and items can be duplicated)
      await waitFor(() => {
        expect(screen.getByText('Duplicate')).toBeInTheDocument()
      })

      // Should not show other items
      expect(screen.queryByText('Edit')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
      expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Delete')).not.toBeInTheDocument()
      expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
    })

    it('only renders share menu items when user can direct share', async () => {
      setUp({
        canEdit: false,
        canDelete: false,
        canAdd: false,
        canDirectShare: true,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Should show share items
      await waitFor(() => {
        expect(screen.getByText('Send To...')).toBeInTheDocument()
      })
      expect(screen.getByText('Copy To...')).toBeInTheDocument()

      // Should not show other items
      expect(screen.queryByText('Edit')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
      expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Delete')).not.toBeInTheDocument()
      expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
    })

    it('renders no menu items when user has no permissions', async () => {
      setUp({
        canEdit: false,
        canDelete: false,
        canAdd: false,
        canDirectShare: false,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      // Should still show external tool items
      await waitFor(() => {
        expect(screen.getByText('External Tool 1')).toBeInTheDocument()
        expect(screen.getByText('External Tool 2')).toBeInTheDocument()
        expect(screen.getByText('External Tool 3')).toBeInTheDocument()
      })

      // Should not show any standard menu items
      expect(screen.queryByText('Edit')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
      expect(screen.queryByText('Move Module...')).not.toBeInTheDocument()
      expect(screen.queryByText('Assign To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Delete')).not.toBeInTheDocument()
      expect(screen.queryByText('Duplicate')).not.toBeInTheDocument()
      expect(screen.queryByText('Send To...')).not.toBeInTheDocument()
      expect(screen.queryByText('Copy To...')).not.toBeInTheDocument()
    })

    it('disables menu button when modules are loading', () => {
      const queryClient = new QueryClient({
        defaultOptions: {
          queries: {
            retry: false,
          },
        },
      })

      const courseId = 'test-course-id'
      const moduleId = 'test-module-id'

      // Don't set any query data to simulate loading state
      const contextProps = {
        ...contextModuleDefaultProps,
        courseId,
      }

      renderMenu({
        moduleId,
        contextProps,
        queryClientOverride: queryClient,
      })

      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      expect(menuButton).toBeDisabled()
    })

    it('disables menu button when there is an error loading modules', () => {
      const courseId = 'test-course-id'
      const moduleId = 'test-module-id'

      // Create a query client that will return an error for the modules query
      const errorQueryClient = new QueryClient({
        defaultOptions: {
          queries: {
            retry: false,
            gcTime: 0,
            queryFn: () => {
              throw new Error('Failed to load modules')
            },
          },
        },
      })

      const contextProps = {
        ...contextModuleDefaultProps,
        courseId,
      }

      renderMenu({
        moduleId,
        contextProps,
        queryClientOverride: errorQueryClient,
      })

      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      expect(menuButton).toBeDisabled()
    })

    it('does not render "Move Contents..." when there is only one module', async () => {
      queryClient.setQueryData([MODULES, 'test-course-id'], {
        pages: [
          {
            modules: [
              {
                _id: 'test-module-id',
                id: 'test-module-id',
                name: 'Test Module',
                position: 1,
                published: true,
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
      queryClient.setQueryData([MODULE_ITEMS, 'test-module-id', null], {
        moduleItems: [
          {
            _id: '1',
            id: '1',
            title: 'Test Item',
            content: {
              canDuplicate: true,
            },
          },
        ],
      })

      const courseId = 'test-course-id'
      const moduleId = 'test-module-id'
      const contextProps = {
        ...contextModuleDefaultProps,
        courseId,
      }

      renderMenu({
        moduleId,
        contextProps,
        queryClientOverride: queryClient,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)
      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument()
      })
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    })

    it('does not render "Move Contents..." when the current module has no items', async () => {
      queryClient.setQueryData([MODULES, 'test-course-id'], {
        pages: [
          {
            modules: [
              {
                _id: 'test-module-id',
                id: 'test-module-id',
                name: 'Test Module',
                position: 1,
                published: true,
                moduleItems: [],
              },
              {
                _id: 'another-module-id',
                id: 'another-module-id',
                name: 'Another Module',
                position: 2,
                published: true,
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
      queryClient.setQueryData([MODULE_ITEMS, 'test-module-id', null], {
        moduleItems: [],
      })
      const courseId = 'test-course-id'
      const moduleId = 'test-module-id'
      const contextProps = {
        ...contextModuleDefaultProps,
        courseId,
      }

      renderMenu({
        moduleId,
        contextProps,
        queryClientOverride: queryClient,
      })
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)
      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument()
      })
      expect(screen.queryByText('Move Contents...')).not.toBeInTheDocument()
    })
  })

  describe('actions', () => {
    const modulePageActionEventHandler = vi.fn()
    beforeAll(() => {
      document.addEventListener('module-action', modulePageActionEventHandler)
    })
    afterAll(() => {
      document.removeEventListener('module-action', modulePageActionEventHandler)
    })

    it('opens the differentiated modules tray on edit', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Edit')).toBeInTheDocument()
      })

      const editMenuItem = screen.getByText('Edit') as HTMLElement
      fireEvent.click(editMenuItem)

      await waitFor(() => {
        expect(handleOpeningModuleUpdateTray).toHaveBeenCalledWith(
          expect.anything(),
          'test-course-id',
          'test-module-id',
          'Test Module 1',
          'settings',
          expect.anything(),
        )
      })
    })

    it('calls handleDelete on delete', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Delete')).toBeInTheDocument()
      })

      const deleteMenuItem = screen.getByText('Delete') as HTMLElement
      fireEvent.click(deleteMenuItem)

      await waitFor(() => {
        expect(handleDelete).toHaveBeenCalledWith(
          'test-module-id',
          'Test Module',
          queryClient,
          'test-course-id',
          expect.anything(),
        )
      })
    })

    it('calls duplicateModule on duplicate', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Duplicate')).toBeInTheDocument()
      })

      const duplicateMenuItem = screen.getByText('Duplicate') as HTMLElement
      fireEvent.click(duplicateMenuItem)

      await waitFor(() => {
        expect(handleDuplicate).toHaveBeenCalledWith(
          'test-module-id',
          'Test Module',
          queryClient,
          'test-course-id',
          expect.anything(),
        )
      })
    })

    it('calls handleSendTo on send to', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Send To...')).toBeInTheDocument()
      })

      const sendToMenuItem = screen.getByText('Send To...') as HTMLElement
      fireEvent.click(sendToMenuItem)

      await waitFor(() => {
        expect(handleSendTo).toHaveBeenCalled()
      })
    })

    it('calls handleCopyTo on copy to', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Copy To...')).toBeInTheDocument()
      })

      const copyToMenuItem = screen.getByText('Copy To...') as HTMLElement
      fireEvent.click(copyToMenuItem)

      await waitFor(() => {
        expect(handleCopyTo).toHaveBeenCalledWith(expect.any(Function))
      })
    })

    it('opens the management tray on move contents', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Move Contents...')).toBeInTheDocument()
      })

      const moveContentsMenuItem = screen.getByText('Move Contents...') as HTMLElement
      fireEvent.click(moveContentsMenuItem)

      await waitFor(() => {
        expect(setIsManagementContentTrayOpenMock).toHaveBeenCalledWith(true)
      })
    })

    it('opens the management tray on move module', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Move Module...')).toBeInTheDocument()
      })

      const moveModuleMenuItem = screen.getByText('Move Module...') as HTMLElement
      fireEvent.click(moveModuleMenuItem)

      await waitFor(() => {
        expect(setIsManagementContentTrayOpenMock).toHaveBeenCalledWith(true)
      })
    })

    it('opens the differentiated modules tray on assign to', async () => {
      setUp()
      const menuButton = screen.getByRole('button', {name: 'Module Options'})
      fireEvent.click(menuButton)

      await waitFor(() => {
        expect(screen.getByText('Assign To...')).toBeInTheDocument()
      })

      const assignToMenuItem = screen.getByText('Assign To...') as HTMLElement
      fireEvent.click(assignToMenuItem)

      await waitFor(() => {
        expect(handleOpeningModuleUpdateTray).toHaveBeenCalledWith(
          expect.anything(),
          'test-course-id',
          'test-module-id',
          'Test Module',
          'assign-to',
          expect.anything(),
        )
      })
    })
  })
})
